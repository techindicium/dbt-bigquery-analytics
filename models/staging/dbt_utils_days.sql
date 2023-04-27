{% set my_query %}
    select cast({{dbt_utils.current_timestamp()}} as date)    /*Result: 2023-04-25*/
{% endset %}

{% if execute %}
    {% set today = run_query(my_query).columns[0].values()[0] %}    /*Result: 2023-04-25*/
    {% set tomorrow = dbt_utils.dateadd('day', 1, "'" ~ today ~ "'") %} /*cast(datetime_add(cast( 2023-04-24 as datetime),interval 1 day)*/
    {% set start_date = var('dbt_bigquery_analytics')['bigquery_analytics_start_date'] %}
    {% else %}
    {% set tomorrow = ' ' %}
    {% set start_date = ' ' %}
{% endif %}

{{ dbt_utils.date_spine(
    datepart="day",
    start_date=start_date,
    end_date=tomorrow
)
}}