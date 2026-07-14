-- stations_snapshot.sql
-- tracks how station data changes over time
-- SCD Type 2 — keeps full history of changes

{% snapshot stations_snapshot %}

{{
    config(
        target_schema = 'SNAPSHOTS',
        unique_key    = 'station_id',
        strategy      = 'check',
        check_cols    = ['status', 'capacity', 'station_name']
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

{% endsnapshot %}