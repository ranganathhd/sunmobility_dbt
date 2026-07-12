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

