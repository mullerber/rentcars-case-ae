with source_data as (

    select *
    from {{ source('raw', 'raw_cancellations') }}

),

deduplicated as (

    select
        *,
        row_number() over (
            partition by cancellation_id
            order by cancelled_at desc
        ) as row_num
    from source_data

),

cleaned as (

    select
        cancellation_id,
        booking_id,
        cast(cancelled_at as timestamp) as cancelled_at,
        lower(reason) as reason,
        lower(cancelled_by) as cancelled_by,
        refund_amount,
        lower(refund_status) as refund_status,
        days_before_pickup,

        case
            when days_before_pickup < 0 then true
            else false
        end as is_late_cancellation

    from deduplicated
    where row_num = 1

)

select *
from cleaned