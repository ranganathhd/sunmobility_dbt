-- stg_swap_records.sql
-- cleans and standardizes raw swap records data

{{
    config(
        materialized = 'view'
    )
}}

SELECT
    swap_id,
    vehicle_id,
    station_id,
    battery_out,
    battery_in,
    swap_date::DATE    AS swap_date,
    swap_time::TIME    AS swap_time,
    operator_id,
    amount::FLOAT      AS amount,
    UPPER(TRIM(status)) AS status
FROM {{ source('raw', 'swap_records') }}
WHERE swap_id IS NOT NULL