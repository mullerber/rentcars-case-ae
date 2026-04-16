with source_data as (

    select *
    from {{ source('raw', 'raw_sessions') }}

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

cleaned as (

    select
        session_id,
        user_id,
        cast(started_at as timestamp) as started_at,
        cast(ended_at as timestamp) as ended_at,
        lower(device) as device,
        upper(country) as country,
        lower(channel) as channel,
        page_views,
        utm_source,
        utm_campaign,
        is_bot,
        case
            when ended_at is not null and ended_at < started_at then true
            else false
        end as is_invalid_session_timing,
        case
            when ended_at is not null and ended_at >= started_at
                then datediff('second', cast(started_at as timestamp), cast(ended_at as timestamp))
            else null
        end as session_duration_seconds
    from deduplicated
    where row_num = 1

)

select *
from cleaned