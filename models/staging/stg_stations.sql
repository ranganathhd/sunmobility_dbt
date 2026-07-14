-- stg_stations.sql
-- cleans and standardizes raw station data

{{
    config(
        materialized = 'view'
    )
}}

SELECT
    station_id,
    UPPER(TRIM(station_name))  AS station_name,
    UPPER(TRIM(city))          AS city,
    UPPER(TRIM(state))         AS state,
    UPPER(TRIM(region))        AS region,
    capacity::INT              AS capacity,
    UPPER(TRIM(status))        AS status,
    installed_date::DATE       AS installed_date
FROM {{ source('raw', 'stations') }}
WHERE station_id IS NOT NULL