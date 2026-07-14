-- dim_battery_packs.sql
-- dimension table for battery packs
-- stores descriptive information about each battery pack

{{
    config(
        materialized = 'table'
    )
}}

SELECT
    battery_id,
    battery_code,
    capacity_kwh,
    manufacture_date,
    manufacturer,
    status,
    cycle_count,
    station_id
FROM {{ ref('stg_battery_packs') }}