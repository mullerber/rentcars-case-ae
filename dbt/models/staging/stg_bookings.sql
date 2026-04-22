with source_data as (

    select *
    from {{ source('raw', 'raw_bookings') }}

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

cleaned as (

    select
        booking_id,
        session_id,
        user_id,
        partner_id,
        cast(booked_at as timestamp) as booked_at,
        cast(pickup_date as date) as pickup_date,
        cast(dropoff_date as date) as dropoff_date,
        trim(lower(pickup_location)) as pickup_location,
        lower(car_category) as car_category,
        daily_rate,
        total_amount,
        upper(currency) as currency,
        lower(status) as status,
        lower(payment_method) as payment_method,

        case
            when dropoff_date is not null and dropoff_date < pickup_date then true
            else false
        end as is_invalid_trip_dates,

        case
            when total_amount < 0 then true
            else false
        end as is_negative_total_amount,

        case
            when total_amount = 0 then true
            else false
        end as is_zero_total_amount,

        case
            when total_amount > 15000 then true
            else false
        end as is_high_total_amount

    from deduplicated
    where row_num = 1

)

select *
from cleaned