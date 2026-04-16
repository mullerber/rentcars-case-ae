with partners as (

    select *
    from {{ ref('stg_partners') }}

),

final as (

    select
        partner_id,
        partner_name,
        country as partner_country,
        tier as partner_tier,
        status as partner_status,
        commission_rate,
        created_at,
        updated_at,
        contact_email,
        is_invalid_commission_rate,

        case
            when status = 'active' then true
            else false
        end as is_active_partner

    from partners

)

select *
from final