-- stores all swap station details
CREATE OR REPLACE TABLE SUNMOBILITY_DB.RAW_DATA.stations (
    station_id       VARCHAR(10),
    station_name     VARCHAR(100),
    city             VARCHAR(50),
    state            VARCHAR(50),
    region           VARCHAR(20),
    capacity         INT,
    status           VARCHAR(20),
    installed_date   DATE
);

-- stores all vehicle and owner details
CREATE OR REPLACE TABLE SUNMOBILITY_DB.RAW_DATA.vehicles (
    vehicle_id       VARCHAR(10),
    vehicle_no       VARCHAR(20),
    owner_name       VARCHAR(100),
    owner_phone      VARCHAR(15),
    owner_email      VARCHAR(100),
    city             VARCHAR(50),
    state            VARCHAR(50),
    vehicle_type     VARCHAR(20),
    registered_date  DATE
);

-- stores all battery pack details
CREATE OR REPLACE TABLE SUNMOBILITY_DB.RAW_DATA.battery_packs (
    battery_id        VARCHAR(10),
    battery_code      VARCHAR(20),
    capacity_kwh      FLOAT,
    manufacture_date  DATE,
    manufacturer      VARCHAR(50),
    status            VARCHAR(20),
    cycle_count       INT,
    station_id        VARCHAR(10)
);

-- stores every battery swap event
CREATE OR REPLACE TABLE SUNMOBILITY_DB.RAW_DATA.swap_records (
    swap_id      VARCHAR(10),
    vehicle_id   VARCHAR(10),
    station_id   VARCHAR(10),
    battery_out  VARCHAR(10),
    battery_in   VARCHAR(10),
    swap_date    DATE,
    swap_time    TIME,
    operator_id  VARCHAR(10),
    amount       FLOAT,
    status       VARCHAR(20)
);


-- check all 4 tables are created in RAW_DATA schema
SHOW TABLES IN SCHEMA SUNMOBILITY_DB.RAW_DATA;


-- ============================================
-- Storage Integration Setup
-- ============================================
CREATE OR REPLACE STORAGE INTEGRATION sunmobility_s3_integration
    TYPE                      = EXTERNAL_STAGE
    STORAGE_PROVIDER          = S3
    ENABLED                   = TRUE
    STORAGE_AWS_ROLE_ARN      = 'arn:aws:iam::719514706906:role/snowflake-s3-role'
    STORAGE_ALLOWED_LOCATIONS = ('s3://awss3bucketranga-v1/sunmobility-data/');

-- ============================================
-- File Format Setup
-- ============================================
CREATE OR REPLACE FILE FORMAT csv_format
    TYPE                = CSV
    FIELD_DELIMITER     = ','
    SKIP_HEADER         = 1
    NULL_IF             = ('NULL', 'null', '')
    EMPTY_FIELD_AS_NULL = TRUE;

-- ============================================
-- External Stage Setup
-- ============================================
CREATE OR REPLACE STAGE sunmobility_s3_stage
    URL                 = 's3://awss3bucketranga-v1/sunmobility-data/'
    STORAGE_INTEGRATION = sunmobility_s3_integration
    FILE_FORMAT         = csv_format;

-- ============================================
-- Snowpipe Setup
-- ============================================
CREATE OR REPLACE PIPE stations_pipe
    AUTO_INGEST = TRUE
AS
COPY INTO stations
FROM @sunmobility_s3_stage/stations.csv
FILE_FORMAT = csv_format;

CREATE OR REPLACE PIPE vehicles_pipe
    AUTO_INGEST = TRUE
AS
COPY INTO vehicles
FROM @sunmobility_s3_stage/vehicles.csv
FILE_FORMAT = csv_format;

CREATE OR REPLACE PIPE battery_packs_pipe
    AUTO_INGEST = TRUE
AS
COPY INTO battery_packs
FROM @sunmobility_s3_stage/battery_packs.csv
FILE_FORMAT = csv_format;

CREATE OR REPLACE PIPE swap_records_pipe
    AUTO_INGEST = TRUE
AS
COPY INTO swap_records
FROM @sunmobility_s3_stage/swap_records.csv
FILE_FORMAT = csv_format;




-- ============================================
-- Stream Setup
-- tracks new rows in swap_records table
-- ============================================
CREATE OR REPLACE STREAM swap_records_stream
    ON TABLE swap_records
    APPEND_ONLY = TRUE;

-- ============================================
-- Processed Table Setup
-- stores processed swap records
-- ============================================
CREATE OR REPLACE TABLE swap_records_processed (
    swap_id      VARCHAR(10),
    vehicle_id   VARCHAR(10),
    station_id   VARCHAR(10),
    battery_out  VARCHAR(10),
    battery_in   VARCHAR(10),
    swap_date    DATE,
    swap_time    TIME,
    operator_id  VARCHAR(10),
    amount       FLOAT,
    status       VARCHAR(20),
    processed_at TIMESTAMP
);

-- ============================================
-- Task Setup
-- runs every 10 minutes
-- checks stream for new data
-- inserts into processed table
-- ============================================
CREATE OR REPLACE TASK swap_records_task
    WAREHOUSE = COMPUTE_WH
    SCHEDULE  = '10 MINUTE'
WHEN
    SYSTEM$STREAM_HAS_DATA('swap_records_stream')
AS
    INSERT INTO swap_records_processed
    SELECT
        swap_id,
        vehicle_id,
        station_id,
        battery_out,
        battery_in,
        swap_date,
        swap_time,
        operator_id,
        amount,
        status,
        CURRENT_TIMESTAMP AS processed_at
    FROM swap_records_stream;

-- resume task
ALTER TASK swap_records_task RESUME;