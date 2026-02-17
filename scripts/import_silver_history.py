import csv
import os
from datetime import datetime

# Config
DOWNLOADED_CSV = r"C:\Users\User-PC\Downloads\XAG_USD Historical Data.csv"
HISTORY_CSV = "output/history.csv"
USD_MYR_RATE = 4.48  # Fixed rate for early 2026 data conversion

def import_history():
    if not os.path.exists(DOWNLOADED_CSV):
        print(f"Error: {DOWNLOADED_CSV} not found.")
        return

    # 1. Read existing history to avoid duplicates
    existing_records = set()
    if os.path.exists(HISTORY_CSV):
        with open(HISTORY_CSV, "r", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for row in reader:
                # Store (timestamp, merchant, item) as a unique key
                existing_records.add((row['timestamp'], row['merchant'], row['item']))

    # 2. Read downloaded history
    new_entries = []
    with open(DOWNLOADED_CSV, "r", encoding="utf-8") as f:
        # Date, Price, Open, High, Low, Vol., Change %
        reader = csv.reader(f)
        header = next(reader)
        
        for row in reader:
            if len(row) < 2:
                continue
            
            raw_date = row[0]  # "02/17/2026"
            raw_price = row[1].replace(",", "")  # "74.4155"
            
            try:
                # Convert date from MM/DD/YYYY to YYYY-MM-DD 00:00:00
                dt = datetime.strptime(raw_date, "%m/%d/%Y")
                timestamp = dt.strftime("%Y-%m-%d 00:00:00")
                usd_oz = float(raw_price)
                
                # Calculate MYR/g
                # 1 oz = 31.1035 grams
                myr_g = round((usd_oz / 31.1035) * USD_MYR_RATE, 2)
                
                # Prepare entries
                # timestamp,merchant,item,sell,buy,spread
                
                # Entry for World Silver (MYR/g)
                if (timestamp, "world_silver", "Silver") not in existing_records:
                    new_entries.append([timestamp, "world_silver", "Silver", str(myr_g), str(myr_g), "0.0"])
                
                # Entry for USD/oz
                if (timestamp, "world_silver", "USD/oz") not in existing_records:
                    new_entries.append([timestamp, "world_silver", "USD/oz", str(usd_oz), str(usd_oz), "0.0"])
                    
            except Exception as e:
                print(f"Error parsing row {row}: {e}")

    if not new_entries:
        print("No new unique entries to add.")
        return

    # 3. Sort entries by date for neatness
    new_entries.sort(key=lambda x: x[0])

    # 4. Append new entries to history.csv
    with open(HISTORY_CSV, "a", encoding="utf-8", newline='') as f:
        writer = csv.writer(f)
        for entry in new_entries:
            writer.writerow(entry)
            print(f"Imported Silver: {entry[0]} | {entry[2]} | {entry[3]}")

    print(f"\nSuccessfully imported {len(new_entries)} silver records into {HISTORY_CSV}.")

if __name__ == "__main__":
    import_history()
