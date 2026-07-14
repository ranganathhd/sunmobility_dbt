-- stg_vehicles.sql
-- cleans and standardizes raw vehicle data

{{
    config(
        materialized = 'view'
    )
}}

SELECT
    vehicle_id,
    UPPER(TRIM(vehicle_no))    AS vehicle_no,
    UPPER(TRIM(owner_name))    AS owner_name,
    TRIM(owner_phone)          AS owner_phone,
    LOWER(TRIM(owner_email))   AS owner_email,
    UPPER(TRIM(city))          AS city,
    UPPER(TRIM(state))         AS state,
    UPPER(TRIM(vehicle_type))  AS vehicle_type,
    registered_date::DATE      AS registered_date
FROM {{ source('raw', 'vehicles') }}
WHERE vehicle_id IS NOT NULL