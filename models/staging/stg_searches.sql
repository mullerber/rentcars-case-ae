with source_data as (

    select *
    from {{ source('raw', 'raw_searches') }}

),

deduplicated as (

    select
        *,
        row_number() over (
            partition by search_id
            order by searched_at desc
        ) as row_num
    from source_data

),

cleaned as (

    select
        search_id,
        session_id,
        cast(searched_at as timestamp) as searched_at,
        trim(lower(pickup_location)) as pickup_location,
        trim(lower(dropoff_location)) as dropoff_location,
        cast(pickup_date as date) as pickup_date,
        cast(dropoff_date as date) as dropoff_date,
        lower(car_category) as car_category,
        num_results,
        partner_id_clicked,
        price_shown,
        case
            when dropoff_date is not null and dropoff_date < pickup_date then true
            else false
        end as is_invalid_trip_dates
    from deduplicated
    where row_num = 1
        and not (
            dropoff_date is not null
            and dropoff_date < pickup_date
  )

)

select *
from cleaned