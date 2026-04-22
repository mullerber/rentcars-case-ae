{% test valid_trip_dates(model, pickup_date_column, dropoff_date_column) %}

select *
from {{ model }}
where {{ dropoff_date_column }} is not null
  and {{ dropoff_date_column }} < {{ pickup_date_column }}

{% endtest %}