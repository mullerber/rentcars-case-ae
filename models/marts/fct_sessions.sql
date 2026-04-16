{{ config(
    materialized='incremental',
    incremental_strategy='delete+insert',
    unique_key='session_id'
) }}

with source_data as (

    select *
    from {{ ref('int_sessions_enriched') }}

    {% if is_incremental() %}
      where started_at > (select coalesce(max(started_at), cast('1900-01-01' as timestamp)) from {{ this }})
    {% endif %}

),

deduplicated as (

    select
        *,
        row_number() over (
            partition by session_id
            order by started_at desc
        ) as row_num
    from source_data

),

final as (

    select
        session_id,
        user_id,
        started_at,
        ended_at,
        channel,
        device,
        country,
        page_views,
        utm_source,
        utm_campaign,
        is_bot,
        total_searches,
        total_bookings,
        has_search,
        has_booking

    from deduplicated
    where row_num = 1

)

select *
from final