with sessions as (

    select * from {{ ref('stg_sessions') }}

),

searches_by_session as (

    select
        session_id,
        count(*) as total_searches
    from {{ ref('stg_searches') }}
    group by 1

),

bookings_by_session as (

    select
        session_id,
        count(*) as total_bookings
    from {{ ref('stg_bookings') }}
    group by 1

),

final as (

    select
        s.session_id,
        s.user_id,
        s.started_at,
        s.ended_at,
        s.channel,
        s.device,
        s.country,
        s.page_views,
        s.utm_source,
        s.utm_campaign,
        s.is_bot,

        coalesce(sb.total_searches, 0) as total_searches,
        coalesce(bb.total_bookings, 0) as total_bookings,

        case
            when coalesce(sb.total_searches, 0) > 0 then true
            else false
        end as has_search,

        case
            when coalesce(bb.total_bookings, 0) > 0 then true
            else false
        end as has_booking

    from sessions s
    left join searches_by_session sb
        on s.session_id = sb.session_id
    left join bookings_by_session bb
        on s.session_id = bb.session_id

)

select * from final