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


----  rbac -----

-- ============================================
-- RBAC Setup for SunMobility Project
-- ============================================

USE ROLE ACCOUNTADMIN;
USE DATABASE SUNMOBILITY_DB;

-- create analyst role — read only access
CREATE ROLE IF NOT EXISTS ANALYST_ROLE;

-- create data engineer role — full access
CREATE ROLE IF NOT EXISTS DATA_ENGINEER_ROLE;

-- grant warehouse access to both roles
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE ANALYST_ROLE;
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE DATA_ENGINEER_ROLE;

-- grant database access
GRANT USAGE ON DATABASE SUNMOBILITY_DB TO ROLE ANALYST_ROLE;
GRANT USAGE ON DATABASE SUNMOBILITY_DB TO ROLE DATA_ENGINEER_ROLE;

-- grant schema access to analyst role — marts only
GRANT USAGE ON SCHEMA SUNMOBILITY_DB.DBT_DEV_DBT_MARTS TO ROLE ANALYST_ROLE;

-- grant schema access to data engineer role — all schemas
GRANT USAGE ON ALL SCHEMAS IN DATABASE SUNMOBILITY_DB TO ROLE DATA_ENGINEER_ROLE;

-- grant select on mart tables to analyst role
GRANT SELECT ON ALL TABLES IN SCHEMA SUNMOBILITY_DB.DBT_DEV_DBT_MARTS TO ROLE ANALYST_ROLE;

-- grant all privileges to data engineer role
GRANT ALL ON ALL TABLES IN DATABASE SUNMOBILITY_DB TO ROLE DATA_ENGINEER_ROLE;
GRANT ALL ON FUTURE TABLES IN DATABASE SUNMOBILITY_DB TO ROLE DATA_ENGINEER_ROLE;

-- create analyst user
CREATE USER IF NOT EXISTS ANALYST_USER
    PASSWORD         = 'Analyst@123'
    DEFAULT_ROLE     = ANALYST_ROLE
    MUST_CHANGE_PASSWORD = FALSE;

-- assign roles to users
GRANT ROLE ANALYST_ROLE        TO USER ANALYST_USER;
GRANT ROLE DATA_ENGINEER_ROLE  TO USER DBT_USER;




---------    rbac --------------------


-- ============================================
-- RBAC Setup for SunMobility Project
-- ============================================

USE ROLE ACCOUNTADMIN;
USE DATABASE SUNMOBILITY_DB;

-- create analyst role — read only access
CREATE ROLE IF NOT EXISTS ANALYST_ROLE;

-- create data engineer role — full access
CREATE ROLE IF NOT EXISTS DATA_ENGINEER_ROLE;

-- grant warehouse access to both roles
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE ANALYST_ROLE;
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE DATA_ENGINEER_ROLE;

-- grant database access
GRANT USAGE ON DATABASE SUNMOBILITY_DB TO ROLE ANALYST_ROLE;
GRANT USAGE ON DATABASE SUNMOBILITY_DB TO ROLE DATA_ENGINEER_ROLE;

-- grant schema access to analyst role — marts only
GRANT USAGE ON SCHEMA SUNMOBILITY_DB.DBT_DEV_DBT_MARTS TO ROLE ANALYST_ROLE;

-- grant schema access to data engineer role — all schemas
GRANT USAGE ON ALL SCHEMAS IN DATABASE SUNMOBILITY_DB TO ROLE DATA_ENGINEER_ROLE;

-- grant select on mart tables to analyst role
GRANT SELECT ON ALL TABLES IN SCHEMA SUNMOBILITY_DB.DBT_DEV_DBT_MARTS TO ROLE ANALYST_ROLE;

-- grant all privileges to data engineer role
GRANT ALL ON ALL TABLES IN DATABASE SUNMOBILITY_DB TO ROLE DATA_ENGINEER_ROLE;
GRANT ALL ON FUTURE TABLES IN DATABASE SUNMOBILITY_DB TO ROLE DATA_ENGINEER_ROLE;

-- create analyst user
CREATE USER IF NOT EXISTS ANALYST_USER
    PASSWORD         = 'Analyst@123'
    DEFAULT_ROLE     = ANALYST_ROLE
    MUST_CHANGE_PASSWORD = FALSE;

-- assign roles to users
GRANT ROLE ANALYST_ROLE        TO USER ANALYST_USER;
GRANT ROLE DATA_ENGINEER_ROLE  TO USER DBT_USER;


-- use accountadmin role
USE ROLE ACCOUNTADMIN;

-- check what users exist in your account
SHOW USERS;


USE ROLE ACCOUNTADMIN;

-- create dbt user
CREATE USER IF NOT EXISTS DBT_USER
    PASSWORD             = 'DBT_Password123'
    DEFAULT_ROLE         = ACCOUNTADMIN
    MUST_CHANGE_PASSWORD = FALSE;

-- grant accountadmin role to dbt user
GRANT ROLE ACCOUNTADMIN TO USER DBT_USER;

-- now grant data engineer role
GRANT ROLE DATA_ENGINEER_ROLE TO USER DBT_USER;

-- ============================================
-- Column Masking Setup for SunMobility Project
-- Applied on mart tables — what analysts query
-- ============================================

USE ROLE ACCOUNTADMIN;
USE DATABASE SUNMOBILITY_DB;

-- ============================================
-- Step 1: Create Masking Policies
-- ============================================

-- masking policy for phone numbers
-- analyst role sees only last 4 digits
-- data engineer and accountadmin see full value
CREATE OR REPLACE MASKING POLICY phone_mask AS
    (val VARCHAR) RETURNS VARCHAR ->
    CASE
        WHEN CURRENT_ROLE() IN ('DATA_ENGINEER_ROLE', 'ACCOUNTADMIN') THEN val
        ELSE CONCAT('XXXXXX', RIGHT(val, 4))
    END;

-- masking policy for email addresses
-- analyst role sees only domain part
-- data engineer and accountadmin see full value
CREATE OR REPLACE MASKING POLICY email_mask AS
    (val VARCHAR) RETURNS VARCHAR ->
    CASE
        WHEN CURRENT_ROLE() IN ('DATA_ENGINEER_ROLE', 'ACCOUNTADMIN') THEN val
        ELSE CONCAT('****@', SPLIT_PART(val, '@', 2))
    END;

-- ============================================
-- Step 2: Apply Masking on dim_vehicles
-- analysts query this table — sensitive columns masked
-- ============================================

DESC TABLE SUNMOBILITY_DB.DBT_DEV_DBT_MARTS.dim_vehicles;

-- mask phone number column


-- mask email column
ALTER TABLE SUNMOBILITY_DB.DBT_DEV_DBT_MARTS.dim_vehicles
    MODIFY COLUMN OWNER_EMAIL SET MASKING POLICY email_mask;

-- ============================================
-- Step 3: Verify masking policies applied
-- ============================================
SHOW MASKING POLICIES;

-- ============================================
-- Step 4: Test masking as analyst role
-- analyst should see masked values
-- ============================================
USE ROLE ACCOUNTADMIN;

-- grant analyst role to your current user
GRANT ROLE ANALYST_ROLE TO USER AUTOMATIONUSER;

-- also grant analyst role access to dim_vehicles
GRANT SELECT ON TABLE SUNMOBILITY_DB.DBT_DEV_DBT_MARTS.dim_vehicles 
    TO ROLE ANALYST_ROLE;

-- now test as analyst role
USE ROLE ANALYST_ROLE;
SELECT
    vehicle_id,
    owner_name,
    owner_email    -- should show ****@gmail.com
FROM SUNMOBILITY_DB.DBT_DEV_DBT_MARTS.dim_vehicles
LIMIT 5;

-- switch back to accountadmin
USE ROLE ACCOUNTADMIN;
SELECT
    vehicle_id,
    owner_name,
    owner_email    -- should show full email
FROM SUNMOBILITY_DB.DBT_DEV_DBT_MARTS.dim_vehicles
LIMIT 5;

