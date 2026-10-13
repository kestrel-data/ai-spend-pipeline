-- Dedupe: a reload can land the same day twice in raw (DATA-102, 2026-09-17
-- had two loads of 2026-09-17 with different _load_id, doubling that day's
-- cost). Keep one row per usage_date/api_key_id/deployment, the latest load.
with ranked as (

    select
        usage_date,
        api_key_id,
        deployment,
        input_tokens,
        output_tokens,
        cast(cost_usd as numeric) as cost_usd,
        _load_id,
        _loaded_at,
        row_number() over (
            partition by usage_date, api_key_id, deployment
            order by _loaded_at desc, _load_id desc
        ) as _rn
    from {{ source('raw', 'azure_openai_usage') }}

)

select
    usage_date,
    api_key_id,
    deployment,
    input_tokens,
    output_tokens,
    cost_usd,
    _load_id,
    _loaded_at,
    concat(cast(usage_date as string), '|', api_key_id, '|', deployment) as _row_key
from ranked
where _rn = 1
