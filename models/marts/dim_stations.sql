-- dim_stations.sql
-- dimension table for swap stations
-- stores descriptive information about each station

{{
    config(
        materialized = 'table'
    )
}}

SELECT
    station_id,
    station_name,
    city,
    state,
    region,
    capacity,
    status,
    installed_date
FROM {{ ref('stg_stations') }}