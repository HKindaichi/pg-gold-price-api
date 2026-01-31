"""
Import historical XAG/USD (Silver) prices and convert to MYR/g
"""
import os
import csv
from datetime import datetime

# Files
INPUT_FILE = r"C:\Users\User-PC\Downloads\XAG_USD Historical Data.csv"
OUTPUT_FILE = "output/history.csv"

# Fixed exchange rate for historical data (fallback)
USD_MYR_RATE = 4.70

def process_history():
    if not os.path.exists(INPUT_FILE):
        print(f"Error: {INPUT_FILE} not found")
        return

    world_silver_entries = []

    # Read historical XAG/USD data
    with open(INPUT_FILE, "r", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        print(f"Columns found: {reader.fieldnames}")
        for row in reader:
            date_str = row.get("Date") or row.get('"Date"')
            price_raw = row.get("Price") or row.get('"Price"')
            
            if not date_str or not price_raw:
                continue

            # Clean price (remove quotes and commas)
            price_usd = float(price_raw.replace(",", "").replace('"', ''))
            
            # Parse date (format: MM/DD/YYYY)
            dt = datetime.strptime(date_str, "%m/%d/%Y")
            timestamp = dt.strftime("%Y-%m-%d %H:%M:%S")
            
            # Convert USD/oz to MYR/g
            # 1 troy oz = 31.1035 grams
            myr_per_g = round((price_usd / 31.1035) * USD_MYR_RATE, 2)
            
            world_silver_entries.append({
                "timestamp": timestamp,
                "merchant": "world_silver",
                "item": "Silver",
                "sell": myr_per_g,
                "buy": myr_per_g,
                "spread": 0.0
            })

    print(f"Processed {len(world_silver_entries)} entries")

    # Read existing history
    existing = set()
    if os.path.exists(OUTPUT_FILE):
        with open(OUTPUT_FILE, "r", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for row in reader:
                key = (row["timestamp"], row["merchant"], row["item"])
                existing.add(key)

    # Append new entries
    new_count = 0
    with open(OUTPUT_FILE, "a", encoding="utf-8") as f:
        for entry in world_silver_entries:
            key = (entry["timestamp"], entry["merchant"], entry["item"])
            if key not in existing:
                f.write(f"{entry['timestamp']},{entry['merchant']},{entry['item']},{entry['sell']},{entry['buy']},{entry['spread']}\n")
                new_count += 1

    print(f"Added {new_count} new historical entries for world_silver.")

if __name__ == "__main__":
    process_history()
