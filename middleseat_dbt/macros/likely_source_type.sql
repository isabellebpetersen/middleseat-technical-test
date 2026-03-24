{% macro likely_source_type(source_type, refcode=none, form_name=none) -%}
{% set search_fields = [refcode, form_name] %}
/* 
    This macro is used for standardizing categories for a donation source by classifying a donation source and putting it into plain English. 
    If a donation source is not already given, it infers the most likely source for a donation based on other fields. 
    With more consistent buckets, we can report more confidently on data for each donation source.
*/
    CASE 
        WHEN {{ source_type }} IS NOT NULL THEN {{ source_type }} --First, if a source type is already specified, use that

        {% for field in search_fields %} -- Search through refcode and form name looking for patterns, evidence of where the donation came from
            WHEN LEFT(lower(replace( {{ field }},'_','-')), 2) = 'em' THEN 'Email'
            WHEN LEFT(lower(replace( {{ field }},'_','-')), 3) = 'ads' THEN 'Ads'
            WHEN lower(replace( {{ field }},'_','-')) ilike '%p2p%' AND lower(replace( {{ field }},'_','-')) ilike '%-rental-%' THEN 'Texting - P2P Rental'
            WHEN lower(replace( {{ field }},'_','-')) ilike '%p2p%' THEN 'Texting - Owned P2P'
            WHEN lower(replace( {{ field }},'_','-')) ilike '%sms%' AND NOT lower(replace( {{ field }},'_','-')) ilike '%p2p%' THEN 'Texting - Broadcast'
            WHEN lower(replace( {{ field }},'_','-')) ilike 'social' THEN 'Social'
            WHEN lower(replace( {{ field }},'_','-')) ilike '%web%' THEN 'Website'
        {% endfor %}
        
        WHEN lower({{ form_name }}) = 'actblue express donor dashboard contribution' THEN 'ActBlue Donor Dashboard' 
    --Specific case where donation came from the Actblue Donor Dashboard
        ELSE NULL --If none of these rules match, leave the donation source empty because there is not any evidence to declare it as anything else
        END

{%- endmacro %}
