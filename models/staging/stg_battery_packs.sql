-- stg_battery_packs.sql
-- cleans and standardizes raw battery pack data

{{
    config(
        materialized = 'view'
    )
}}

SELECT
    battery_id,
    UPPER(TRIM(battery_code))   AS battery_code,
    capacity_kwh::FLOAT         AS capacity_kwh,
    manufacture_date::DATE      AS manufacture_date,
    UPPER(TRIM(manufacturer))   AS manufacturer,
    UPPER(TRIM(status))         AS status,
    cycle_count::INT            AS cycle_count,
    station_id
FROM {{ source('raw', 'battery_packs') }}
WHERE battery_id IS NOT NULL