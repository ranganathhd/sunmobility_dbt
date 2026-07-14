-- int_swaps_enriched.sql
-- joins all staging tables together
-- adds business logic and enriched columns

{{
    config(
        materialized = 'ephemeral'
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
    s.status                        AS swap_status,
    v.owner_name,
    v.owner_email,
    v.city                          AS owner_city,
    v.state                         AS owner_state,
    v.vehicle_type,
    st.station_name,
    st.city                         AS station_city,
    st.state                        AS station_state,
    st.region,
    b_out.battery_code              AS battery_out_code,
    b_out.manufacturer              AS battery_out_manufacturer,
    b_in.battery_code               AS battery_in_code,
    b_in.manufacturer               AS battery_in_manufacturer,
    -- business logic — categorize swap amount
    CASE
        WHEN s.amount >= 150 THEN 'High'
        WHEN s.amount >= 100 THEN 'Medium'
        ELSE 'Low'
    END                             AS amount_category,
    -- extract month and year for reporting
    MONTH(s.swap_date)              AS swap_month,
    YEAR(s.swap_date)               AS swap_year
FROM {{ ref('stg_swap_records') }}  s
JOIN {{ ref('stg_vehicles') }}      v     ON s.vehicle_id  = v.vehicle_id
JOIN {{ ref('stg_stations') }}      st    ON s.station_id  = st.station_id
JOIN {{ ref('stg_battery_packs') }} b_out ON s.battery_out = b_out.battery_id
JOIN {{ ref('stg_battery_packs') }} b_in  ON s.battery_in  = b_in.battery_id