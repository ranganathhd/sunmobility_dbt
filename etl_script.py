# etl_script.py
# This script generates realistic SunMobility sample data
# saves as CSV files and uploads to AWS S3

import pandas as pd
import boto3
import os
import random
from faker import Faker
from datetime import datetime, timedelta
from dotenv import load_dotenv

# load environment variables from .env file
load_dotenv()

# initialize faker with Indian locale for realistic Indian data
fake = Faker('en_IN')

# ============================================
# Step 1 — Generate Stations Data
# 10 swap stations across India
# ============================================
def generate_stations():
    stations = [
        {'station_id': 'S001', 'station_name': 'Anna Nagar Station',     'city': 'Chennai',   'state': 'Tamil Nadu',    'region': 'South', 'capacity': 10, 'status': 'Active',   'installed_date': '2022-01-15'},
        {'station_id': 'S002', 'station_name': 'Bandra Station',         'city': 'Mumbai',    'state': 'Maharashtra',   'region': 'West',  'capacity': 12, 'status': 'Active',   'installed_date': '2022-02-20'},
        {'station_id': 'S003', 'station_name': 'Koramangala Station',    'city': 'Bangalore', 'state': 'Karnataka',     'region': 'South', 'capacity': 15, 'status': 'Active',   'installed_date': '2022-03-10'},
        {'station_id': 'S004', 'station_name': 'Connaught Place Station','city': 'Delhi',     'state': 'Delhi',         'region': 'North', 'capacity': 20, 'status': 'Active',   'installed_date': '2022-04-05'},
        {'station_id': 'S005', 'station_name': 'Salt Lake Station',      'city': 'Kolkata',   'state': 'West Bengal',   'region': 'East',  'capacity': 8,  'status': 'Active',   'installed_date': '2022-05-18'},
        {'station_id': 'S006', 'station_name': 'Banjara Hills Station',  'city': 'Hyderabad', 'state': 'Telangana',     'region': 'South', 'capacity': 10, 'status': 'Active',   'installed_date': '2022-06-22'},
        {'station_id': 'S007', 'station_name': 'Navrangpura Station',    'city': 'Ahmedabad', 'state': 'Gujarat',       'region': 'West',  'capacity': 9,  'status': 'Inactive', 'installed_date': '2022-07-30'},
        {'station_id': 'S008', 'station_name': 'Aundh Station',          'city': 'Pune',      'state': 'Maharashtra',   'region': 'West',  'capacity': 11, 'status': 'Active',   'installed_date': '2022-08-14'},
        {'station_id': 'S009', 'station_name': 'Gomti Nagar Station',    'city': 'Lucknow',   'state': 'Uttar Pradesh', 'region': 'North', 'capacity': 7,  'status': 'Active',   'installed_date': '2022-09-01'},
        {'station_id': 'S010', 'station_name': 'Alwarpet Station',       'city': 'Chennai',   'state': 'Tamil Nadu',    'region': 'South', 'capacity': 13, 'status': 'Active',   'installed_date': '2022-10-10'},
    ]
    return pd.DataFrame(stations)

# ============================================
# Step 2 — Generate Vehicles Data
# 50 vehicles registered across India
# ============================================
def generate_vehicles():
    vehicle_types = ['Two Wheeler', 'Three Wheeler']
    states = [
        'Tamil Nadu', 'Maharashtra', 'Karnataka', 'Delhi',
        'West Bengal', 'Telangana', 'Gujarat', 'Uttar Pradesh',
        'Rajasthan', 'Kerala'
    ]
    cities = [
        'Chennai', 'Mumbai', 'Bangalore', 'Delhi', 'Kolkata',
        'Hyderabad', 'Ahmedabad', 'Pune', 'Lucknow', 'Surat',
        'Jaipur', 'Kochi', 'Coimbatore', 'Nagpur', 'Indore'
    ]

    vehicles = []
    for i in range(1, 51):  # 50 vehicles
        vehicle_id   = f'V{str(i).zfill(3)}'
        vehicle_no   = fake.license_plate()
        owner_name   = fake.name()
        owner_phone  = f'9{random.randint(100000000, 999999999)}'
        owner_email  = fake.email()
        city         = random.choice(cities)
        state        = random.choice(states)
        vehicle_type = random.choice(vehicle_types)
        reg_date     = fake.date_between(start_date='-3y', end_date='-1y')

        vehicles.append({
            'vehicle_id'      : vehicle_id,
            'vehicle_no'      : vehicle_no,
            'owner_name'      : owner_name,
            'owner_phone'     : owner_phone,
            'owner_email'     : owner_email,
            'city'            : city,
            'state'           : state,
            'vehicle_type'    : vehicle_type,
            'registered_date' : reg_date
        })
    return pd.DataFrame(vehicles)

# ============================================
# Step 3 — Generate Battery Packs Data
# 60 battery packs across all stations
# ============================================
def generate_battery_packs():
    manufacturers = [
        'Exide', 'Amara Raja', 'Luminous',
        'Okaya', 'Livguard', 'Tata Green',
        'HBL Power', 'Su-Kam'
    ]
    statuses    = ['Available', 'Available', 'In Use', 'In Use', 'Faulty']
    station_ids = [f'S{str(i).zfill(3)}' for i in range(1, 11)]

    batteries = []
    for i in range(1, 61):  # 60 batteries
        battery_id       = f'B{str(i).zfill(3)}'
        battery_code     = f'SM-BAT-{str(i).zfill(4)}'
        capacity_kwh     = round(random.choice([1.5, 2.0, 2.5, 3.0, 3.5]), 1)
        manufacture_date = fake.date_between(start_date='-2y', end_date='-6m')
        manufacturer     = random.choice(manufacturers)
        status           = random.choice(statuses)
        cycle_count      = random.randint(10, 800)
        station_id       = random.choice(station_ids)

        batteries.append({
            'battery_id'      : battery_id,
            'battery_code'    : battery_code,
            'capacity_kwh'    : capacity_kwh,
            'manufacture_date': manufacture_date,
            'manufacturer'    : manufacturer,
            'status'          : status,
            'cycle_count'     : cycle_count,
            'station_id'      : station_id
        })
    return pd.DataFrame(batteries)

# ============================================
# Step 4 — Generate Swap Records Data
# 500 swap events across all stations and vehicles
# ============================================
def generate_swap_records():
    vehicle_ids  = [f'V{str(i).zfill(3)}' for i in range(1, 51)]
    station_ids  = [f'S{str(i).zfill(3)}' for i in range(1, 11)]
    battery_ids  = [f'B{str(i).zfill(3)}' for i in range(1, 61)]
    operator_ids = [f'OP{str(i).zfill(2)}' for i in range(1, 11)]
    statuses     = ['Success', 'Success', 'Success', 'Success', 'Failed']

    swaps      = []
    start_date = datetime(2024, 1, 1)

    for i in range(1, 501):  # 500 swap records
        swap_id     = f'SW{str(i).zfill(4)}'
        vehicle_id  = random.choice(vehicle_ids)
        station_id  = random.choice(station_ids)
        battery_out = random.choice(battery_ids)
        battery_in  = random.choice([b for b in battery_ids if b != battery_out])
        swap_date   = start_date + timedelta(days=random.randint(0, 365))
        swap_time   = f'{random.randint(6, 22):02d}:{random.randint(0, 59):02d}:00'
        operator_id = random.choice(operator_ids)
        amount      = random.choice([50.0, 75.0, 100.0, 125.0, 150.0, 175.0, 200.0])
        status      = random.choice(statuses)

        swaps.append({
            'swap_id'    : swap_id,
            'vehicle_id' : vehicle_id,
            'station_id' : station_id,
            'battery_out': battery_out,
            'battery_in' : battery_in,
            'swap_date'  : swap_date.strftime('%Y-%m-%d'),
            'swap_time'  : swap_time,
            'operator_id': operator_id,
            'amount'     : amount,
            'status'     : status
        })
    return pd.DataFrame(swaps)

# ============================================
# Step 5 — Save DataFrames as CSV files
# saves each table as a CSV in data/ folder
# ============================================
def save_to_csv(df, filename):
    # create data folder if it does not exist
    os.makedirs('data', exist_ok=True)
    filepath = f'data/{filename}'
    # index=False means do not save row numbers as a column
    df.to_csv(filepath, index=False)
    print(f'Saved {filename} — {len(df)} rows')
    return filepath

# ============================================
# Step 6 — Upload CSV files to AWS S3
# uploads each CSV to sunmobility-data/ folder in S3
# ============================================
def upload_to_s3(filepath, filename):
    # create S3 client using credentials from .env file
    s3 = boto3.client(
        's3',
        aws_access_key_id     = os.getenv('AWS_ACCESS_KEY_ID'),
        aws_secret_access_key = os.getenv('AWS_SECRET_ACCESS_KEY'),
        region_name           = os.getenv('AWS_REGION')
    )

    bucket_name = os.getenv('AWS_BUCKET_NAME')
    # s3_key is the folder path + filename inside S3 bucket
    s3_key      = f'sunmobility-data/{filename}'

    # upload file from local data/ folder to S3
    s3.upload_file(filepath, bucket_name, s3_key)
    print(f'Uploaded {filename} to s3://{bucket_name}/{s3_key}')

# ============================================
# Step 7 — Main function
# runs all steps in correct order
# ============================================
def main():
    print('Starting SunMobility ETL Pipeline...')
    print('=' * 50)

    # Step 1: generate all data
    print('Generating data...')
    df_stations  = generate_stations()
    df_vehicles  = generate_vehicles()
    df_batteries = generate_battery_packs()
    df_swaps     = generate_swap_records()

    # Step 2: save to CSV files
    print('\nSaving CSV files...')
    stations_file  = save_to_csv(df_stations,  'stations.csv')
    vehicles_file  = save_to_csv(df_vehicles,  'vehicles.csv')
    batteries_file = save_to_csv(df_batteries, 'battery_packs.csv')
    swaps_file     = save_to_csv(df_swaps,     'swap_records.csv')

    # Step 3: upload CSV files to S3
    print('\nUploading to S3...')
    upload_to_s3(stations_file,  'stations.csv')
    upload_to_s3(vehicles_file,  'vehicles.csv')
    upload_to_s3(batteries_file, 'battery_packs.csv')
    upload_to_s3(swaps_file,     'swap_records.csv')

    print('\n' + '=' * 50)
    print('ETL Pipeline completed successfully!')
    print(f'Stations     : 10 rows')
    print(f'Vehicles     : 50 rows')
    print(f'Battery Packs: 60 rows')
    print(f'Swap Records : 500 rows')

# entry point — runs main() when script is executed
if __name__ == '__main__':
    main()