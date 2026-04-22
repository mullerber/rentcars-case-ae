{{ config(
    materialized='incremental',
    incremental_strategy='delete+insert',
    unique_key='booking_id'
) }}

with source_data as (

    select *
    from {{ ref('int_bookings_enriched') }}

    {% if is_incremental() %}
      where booked_at >= (select coalesce(max(booked_at), cast('1900-01-01' as timestamp)) from {{ this }})
    {% endif %}

),

deduplicated as (

    select
        *,
        row_number() over (
            partition by booking_id
            order by booked_at desc
        ) as row_num
    from source_data

),

final as (

    select
        booking_id,
        session_id,
        user_id,
        partner_id,
        booked_at,
        pickup_date,
        dropoff_date,
        pickup_location,
        car_category,
        daily_rate,
        total_amount,
        currency,
        booking_status,
        payment_method,

        partner_name,
        partner_country,
        partner_tier,
        partner_status,
        commission_rate,

        cancellation_id,
        cancelled_at,
        cancellation_reason,
        cancelled_by,
        refund_amount,
        refund_status,
        days_before_pickup,
        is_late_cancellation,
        has_cancellation,

        is_invalid_trip_dates,
        is_negative_total_amount,
        is_zero_total_amount,
        is_high_total_amount,
        is_valid_revenue_booking,
        valid_revenue_amount

    from deduplicated
    where row_num = 1

)

select *
from final