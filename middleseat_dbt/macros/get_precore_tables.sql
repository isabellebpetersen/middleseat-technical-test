{%- macro get_precore_tables(schema_pattern, model_name, schema_exclude=[], model_include=[], model_exclude=[]) -%}
/*
    This macro looks in the database for tables that match a specific naming pattern (schema_pattern),
    then gives back those tables so that we can use them in a model. Returns the references to these tables,
    so they can be referenced/combined/transformed later on.
*/ 
    
{%- if execute -%}

    {%- call statement('get_tables', fetch_result=True) -%}
        SELECT distinct --Look in the database catalog of tables, find the tables that match the given schema pattern (taking into account the following)
            table_schema,
            table_name
        FROM INFORMATION_SCHEMA.TABLES
        WHERE table_schema ilike '{{ schema_pattern }}'

        {% if target.name != 'dev' -%} --Exclude development tables, avoids accidentally using them in a production context
            AND table_schema NOT LIKE '%_dev%'
        {%- endif %}

        {% if schema_exclude -%} --Allows us to exclude specific schemas that we don't want
            AND table_schema NOT IN ( 
                {%- for schema in schema_exclude -%}
                    '{{ schema }}'{%- if not loop.last -%},{%- endif -%}
                {%- endfor -%} )
        {%- endif %}

    -- There are two possible options for model name (sequence or string), and each needs to be handled differently
        {% if model_name is sequence and model_name is not string -%}
            AND table_name IN (
                {%- for tbl in model_name -%}
                    '{{ tbl }}'{%- if not loop.last -%},{%- endif -%}
                {%- endfor -%} )
        {% else -%} --If model_name is a string, 
            AND (table_name ILIKE '{{ model_name }}'

            {% if model_include -%} --Gives the option to explicitly name certain tables to include
                OR table_name IN (
                {%- for tbl in model_include -%}
                    '{{ tbl }}'{%- if not loop.last -%},{%- endif -%}
                {%- endfor -%} )
            {%- endif %}

            )
        {%- endif %}

        {% if model_exclude -%} --Gives the option to explicitly name certain tables to exclude
            AND table_name NOT IN ( 
                {%- for tbl in model_exclude -%}
                    '{{ tbl }}'{%- if not loop.last -%},{%- endif -%}
                {%- endfor -%} )
        {%- endif %}

        ORDER BY 1,2 --Sort results by table schema, then table name
    {%- endcall -%} --At this point, the resulting matching tables are stored as get_tables

    {%- set table_list = load_result('get_tables') -%} --Loads the resulting tables into a variable

    {%- if table_list and table_list['table'] -%} --Creates a list to hold the resulting tables
        {%- set tbl_relations = [] -%}
        {%- for row in table_list['table'] -%} --Keeps each resulting table as a dbt relation (a specific object type that can be properly referenced later)
            {%- set tbl = api.Relation.create(
                database=database,
                schema=row.table_schema,
                identifier=row.table_name
            ) -%}

            {%- do tbl_relations.append(tbl) -%}
        {%- endfor -%}

        {# {{ log("tables: " ~ tbl_relations, info=True) }} #}
        {{ return(tbl_relations) }}

    {%- else -%} --If nothing matched, return an empty list
        {{ log("no tables found.", info=True) }}
        {{ return([]) }}
    {%- endif -%}

{% endif %}

{%- endmacro -%}
