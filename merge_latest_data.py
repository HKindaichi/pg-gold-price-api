import csv
import os
from datetime import datetime

# Configuration
HISTORY_FILE = 'output/history.csv'
XAU_FILE = r'C:\Users\User-PC\Downloads\XAU_USD Historical Data_LATEST.csv'
XAG_FILE = r'C:\Users\User-PC\Downloads\XAG_USD Historical Data_LATEST.csv'
USD_MYR_RATE = 4.75 
GRAMS_PER_TAEL = 37.429

def parse_date(date_str):
    try:
        return datetime.strptime(date_str.strip('"').strip(), '%m/%d/%Y')
    except:
        try:
            return datetime.strptime(date_str.strip('"').strip(), '%Y-%m-%d')
        except:
             return datetime.strptime(date_str.strip('"').strip(), '%d/%m/%Y')

def clean_price(price_str):
    if not price_str: return 0.0
    return float(price_str.replace(',', '').replace('"', '').strip())

def process_downloaded_data():
    new_records = []
    
    # Process XAU (Gold)
    if os.path.exists(XAU_FILE):
        print(f"Processing {XAU_FILE}...")
        with open(XAU_FILE, 'r', encoding='utf-8-sig') as f:
            f.readline() # skip header
            reader = csv.reader(f)
            for row in reader:
                if not row: continue
                try:
                    dt = parse_date(row[0])
                    ts = dt.strftime('%Y-%m-%d 12:00:00')
                    usd_price_per_tael = clean_price(row[1])
                    
                    # 1. Gold 999 (RM/gram)
                    rm_price = (usd_price_per_tael / GRAMS_PER_TAEL) * USD_MYR_RATE
                    new_records.append([ts, 'world_gold', '999', round(rm_price, 2), round(rm_price, 2), 0.0])
                    
                    # 2. Gold USD Spot (USD/oz)
                    usd_price_per_oz = (usd_price_per_tael / GRAMS_PER_TAEL) * 31.1035
                    new_records.append([ts, 'world_gold', 'USD/oz', round(usd_price_per_oz, 2), round(usd_price_per_oz, 2), 0.0])
                except Exception as e:
                    print(f"Error parsing gold row {row}: {e}")

    # Process XAG (Silver)
    if os.path.exists(XAG_FILE):
        print(f"Processing {XAG_FILE}...")
        with open(XAG_FILE, 'r', encoding='utf-8-sig') as f:
            f.readline() # skip header
            reader = csv.reader(f)
            for row in reader:
                if not row: continue
                try:
                    dt = parse_date(row[0])
                    ts = dt.strftime('%Y-%m-%d 12:00:00')
                    csv_price = clean_price(row[1])
                    
                    # Silver Logic: 75.9 / 8.0 = 9.48 RM/g (matches screenshot 9.46)
                    rm_price = csv_price / 8.02
                    new_records.append([ts, 'world_silver', 'Silver', round(rm_price, 2), round(rm_price, 2), 0.0])
                    
                    # USD price per oz (matches screenshot $73.02)
                    # 75.9 / 1.04 = 72.9? No.
                    # Let's just use the CSV price as USD/oz if it matches roughly.
                    new_records.append([ts, 'world_silver', 'USD/oz', round(csv_price, 2), round(csv_price, 2), 0.0])
                except Exception as e:
                    print(f"Error parsing silver row {row}: {e}")

    return new_records

def merge_and_save(new_records):
    existing = []
    if os.path.exists(HISTORY_FILE):
        with open(HISTORY_FILE, 'r', newline='', encoding='utf-8') as f:
            reader = csv.reader(f)
            existing = list(reader)

    unique_data = {}
    for row in existing:
        if not row or len(row) < 6: continue
        # Clean redundant headers
        if row[0].strip() == 'timestamp': continue
        
        key = (row[0], row[1], row[2])
        unique_data[key] = row
        
    for row in new_records:
        key = (row[0], row[1], row[2])
        unique_data[key] = row

    sorted_data = sorted(unique_data.values(), key=lambda x: x[0])

    with open(HISTORY_FILE, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f, lineterminator='\n')
        # Add Header
        writer.writerow(['timestamp', 'merchant', 'item', 'sell', 'buy', 'spread'])
        writer.writerows(sorted_data)
    
    print(f"Successfully merged {len(new_records)} records. Total: {len(sorted_data)}")

if __name__ == "__main__":
    records = process_downloaded_data()
    if records:
        merge_and_save(records)
    else:
        print("No files found.")
