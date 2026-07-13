# pg_to_s3.py
# This script connects to PostgreSQL (pg admin)
# extracts data from all 4 tables
# saves as CSV files and uploads to AWS S3
# This is how it works in real production at SunMobility

import pandas as pd
import psycopg2
import boto3
import os
from dotenv import load_dotenv

# load environment variables from .env file
load_dotenv()

# ============================================
# Step 1 — Connect to PostgreSQL
# ============================================
def connect_postgres():
    # connect to PostgreSQL using credentials from .env file
    conn = psycopg2.connect(
        host     = os.getenv('PG_HOST'),       # PostgreSQL server address
        port     = os.getenv('PG_PORT'),       # PostgreSQL port — default 5432
        database = os.getenv('PG_DATABASE'),   # database name in pg admin
        user     = os.getenv('PG_USER'),       # pg admin username
        password = os.getenv('PG_PASSWORD')    # pg admin password
    )
    print('Connected to PostgreSQL successfully')
    return conn

# ============================================
# Step 2 — Extract data from PostgreSQL
# ============================================
def extract_from_postgres(conn, table_name):
    # read entire table from PostgreSQL into pandas DataFrame
    # pd.read_sql runs SQL query and returns result as DataFrame
    query = f'SELECT * FROM {table_name}'
    df    = pd.read_sql(query, conn)
    print(f'Extracted {table_name} — {len(df)} rows')
    return df

# ============================================
# Step 3 — Save DataFrame as CSV file
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
# Step 4 — Upload CSV files to AWS S3
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
    # s3_key is the folder path inside S3 bucket
    s3_key      = f'sunmobility-data/{filename}'

    # upload file from local data/ folder to S3
    s3.upload_file(filepath, bucket_name, s3_key)
    print(f'Uploaded {filename} to s3://{bucket_name}/{s3_key}')

# ============================================
# Step 5 — Main function
# runs all steps in correct order
# ============================================
def main():
    print('Starting SunMobility PostgreSQL to S3 Pipeline...')
    print('=' * 50)

    # Step 1: connect to PostgreSQL
    conn = connect_postgres()

    try:
        # Step 2: extract all 4 tables from PostgreSQL
        print('\nExtracting data from PostgreSQL...')
        df_stations  = extract_from_postgres(conn, 'stations')
        df_vehicles  = extract_from_postgres(conn, 'vehicles')
        df_batteries = extract_from_postgres(conn, 'battery_packs')
        df_swaps     = extract_from_postgres(conn, 'swap_records')

        # Step 3: save to CSV files
        print('\nSaving CSV files...')
        stations_file  = save_to_csv(df_stations,  'stations.csv')
        vehicles_file  = save_to_csv(df_vehicles,  'vehicles.csv')
        batteries_file = save_to_csv(df_batteries, 'battery_packs.csv')
        swaps_file     = save_to_csv(df_swaps,     'swap_records.csv')

        # Step 4: upload CSV files to S3
        print('\nUploading to S3...')
        upload_to_s3(stations_file,  'stations.csv')
        upload_to_s3(vehicles_file,  'vehicles.csv')
        upload_to_s3(batteries_file, 'battery_packs.csv')
        upload_to_s3(swaps_file,     'swap_records.csv')

        print('\n' + '=' * 50)
        print('Pipeline completed successfully!')
        print(f'Stations     : {len(df_stations)} rows')
        print(f'Vehicles     : {len(df_vehicles)} rows')
        print(f'Battery Packs: {len(df_batteries)} rows')
        print(f'Swap Records : {len(df_swaps)} rows')

    except Exception as e:
        # if anything goes wrong — log the error
        print(f'Pipeline failed: {e}')

    finally:
        # always close PostgreSQL connection
        conn.close()
        print('PostgreSQL connection closed')

# entry point — runs main() when script is executed
if __name__ == '__main__':
    main()

# # PostgreSQL connection details
# PG_HOST=localhost
# PG_PORT=5432
# PG_DATABASE=sunmobility_db
# PG_USER=postgres
# PG_PASSWORD=your_pg_password

# # AWS credentials
# AWS_ACCESS_KEY_ID=your_access_key
# AWS_SECRET_ACCESS_KEY=your_secret_key
# AWS_BUCKET_NAME=awss3bucketranga-v1
# AWS_REGION=eu-north-1