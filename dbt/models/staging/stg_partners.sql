with source_data as (

    select *
    from {{ source('raw', 'raw_partners') }}

),

deduplicated as (

    select
        *,
        row_number() over (
            partition by partner_id
            order by coalesce(updated_at, created_at) desc
        ) as row_num
    from source_data

),

cleaned as (

    select
        partner_id,
        partner_name,
        upper(country) as country,
        lower(tier) as tier,
        lower(status) as status,
        commission_rate,
        cast(created_at as timestamp) as created_at,
        cast(updated_at as timestamp) as updated_at,
        lower(contact_email) as contact_email,

        case
            when commission_rate < 0.05 or commission_rate > 0.30 then true
            else false
        end as is_invalid_commission_rate

    from deduplicated
    where row_num = 1

)

select *
from cleaned