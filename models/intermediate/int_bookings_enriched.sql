with bookings as (

    select * from {{ ref('stg_bookings') }}

),

partners as (

    select * from {{ ref('stg_partners') }}

),

cancellations as (

    select * from {{ ref('stg_cancellations') }}

),

final as (

    select
        b.booking_id,
        b.session_id,
        b.user_id,
        b.partner_id,
        b.booked_at,
        b.pickup_date,
        b.dropoff_date,
        b.pickup_location,
        b.car_category,
        b.daily_rate,
        b.total_amount,
        b.currency,
        b.status as booking_status,
        b.payment_method,

        b.is_invalid_trip_dates,
        b.is_negative_total_amount,
        b.is_zero_total_amount,
        b.is_high_total_amount,

        p.partner_name,
        p.country as partner_country,
        p.tier as partner_tier,
        p.status as partner_status,
        p.commission_rate,

        c.cancellation_id,
        c.cancelled_at,
        c.reason as cancellation_reason,
        c.cancelled_by,
        c.refund_amount,
        c.refund_status,
        c.days_before_pickup,
        c.is_late_cancellation,

        case
            when c.cancellation_id is not null then true
            else false
        end as has_cancellation,

        case
            when b.status in ('confirmed', 'completed')
             and p.status = 'active'
             and coalesce(b.is_invalid_trip_dates, false) = false
             and coalesce(b.is_negative_total_amount, false) = false
             and coalesce(b.is_zero_total_amount, false) = false
            then true
            else false
        end as is_valid_revenue_booking,

        case
            when b.status in ('confirmed', 'completed')
             and p.status = 'active'
             and coalesce(b.is_invalid_trip_dates, false) = false
             and coalesce(b.is_negative_total_amount, false) = false
             and coalesce(b.is_zero_total_amount, false) = false
            then b.total_amount
            else null
        end as valid_revenue_amount

    from bookings b
    left join partners p
        on b.partner_id = p.partner_id
    left join cancellations c
        on b.booking_id = c.booking_id

)

select * from final