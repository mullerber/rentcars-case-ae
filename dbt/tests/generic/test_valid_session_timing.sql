{% test valid_session_timing(model, started_at_column, ended_at_column) %}

select *
from {{ model }}
where {{ ended_at_column }} is not null
  and {{ ended_at_column }} < {{ started_at_column }}

{% endtest %}