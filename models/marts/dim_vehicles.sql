-- dim_vehicles.sql
-- dimension table for vehicles
-- stores descriptive information about each vehicle and owner

{{
    config(
        materialized = 'table'
    )
}}

SELECT
    vehicle_id,
    vehicle_no,
    owner_name,
    owner_email,
    city,
    state,
    vehicle_type,
    registered_date
FROM {{ ref('stg_vehicles') }}