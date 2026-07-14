-- fct_swaps.sql
-- fact table for swap events
-- incremental model — only loads new records each run

{{
    config(
        materialized = 'incremental',
        unique_key   = 'swap_id',
        cluster_by   = ['swap_date', 'region']
    )
}}

SELECT
    s.swap_id,
    s.vehicle_id,
    s.station_id,
    s.battery_out,
    s.battery_in,
    s.swap_date,
    s.swap_time,
    s.operator_id,
    s.amount,
    s.swap_status,
    s.owner_name,
    s.owner_city,
    s.owner_state,
    s.vehicle_type,
    s.station_name,
    s.station_city,
    s.station_state,
    s.region,
    s.amount_category,
    s.swap_month,
    s.swap_year
FROM {{ ref('int_swaps_enriched') }} s

{% if is_incremental() %}
    -- only load new records not already in fct_swaps
    WHERE s.swap_date > (SELECT MAX(swap_date) FROM {{ this }})
{% endif %}