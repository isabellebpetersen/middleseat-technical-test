{{
    config(
        dist='wdl_client_code',
        sort=['wdl_client_code', 'likely_source_type']
    )
}}
/*
    This model keeps one transaction per row, the idea being that later downstream I can have 
    more flexibility with aggregating by source type, date, recurring status, or any other 
    dimensions I choose. I also added a dimension to describe who the donor was, which could be 
    useful later on if I wanted to report on the level of unique donors. Note that given the constraints of 
    this test, my dashboard still ended up being aggregated at the date/source level but given the chance to 
    structure the reporting table myself I would have given myself the flexibility to aggregate all of this
    later in Looker (or Tableau). 
*/
SELECT
    wdl_client_code,
    wdl_transaction_id,
    et_created_at,
    CAST(et_created_at AS DATE) AS et_created_date,
    COALESCE(likely_source_type, 'None') AS likely_source_type,
    LOWER(NULLIF(TRIM(email), '')) AS donor_id --normalized donor id using email (best available cross-platform identifier).*
    form_managing_entity_committee_name,
    committee_name,
    is_recurring,
    COALESCE(recurring_type, 'None') AS recurring_type,
    post_refund_amount
FROM {{ ref('core__donations')}}

/*
    *Note: for the donor id, I would like it to be a more anonymized hash to signify unique donors. 
    But given my constraints here I just chose to use email for the sake of showing I would want a field like this.
*/
