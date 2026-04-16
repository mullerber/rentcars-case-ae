with sessions as (

    select
        user_id,
        started_at
    from {{ ref('stg_sessions') }}
    where user_id is not null

),

bookings as (

    select
        user_id,
        booked_at
    from {{ ref('stg_bookings') }}
    where user_id is not null

),

sessions_agg as (

    select
        user_id,
        min(started_at) as first_session_at,
        max(started_at) as last_session_at,
        count(*) as total_sessions
    from sessions
    group by 1

),

bookings_agg as (

    select
        user_id,
        min(booked_at) as first_booking_at,
        max(booked_at) as last_booking_at,
        count(*) as total_bookings
    from bookings
    group by 1

),

all_users as (

    select user_id from sessions
    union
    select user_id from bookings

),

final as (

    select
        u.user_id,
        s.first_session_at,
        s.last_session_at,
        coalesce(s.total_sessions, 0) as total_sessions,
        b.first_booking_at,
        b.last_booking_at,
        coalesce(b.total_bookings, 0) as total_bookings

    from all_users u
    left join sessions_agg s
        on u.user_id = s.user_id
    left join bookings_agg b
        on u.user_id = b.user_id

)

select *
from final