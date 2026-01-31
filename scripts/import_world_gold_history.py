import csv
import os
from datetime import datetime

INPUT_FILE = "xau_usd_historical.csv"
OUTPUT_FILE = os.path.join("output", "history.csv")
USD_MYR_RATE = 4.70  # Fixed rate for historical processing

def process_history():
    if not os.path.exists(INPUT_FILE):
        print(f"File {INPUT_FILE} not found.")
        return

    world_gold_entries = []
    
    with open(INPUT_FILE, "r", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        print(f"Columns found: {reader.fieldnames}")
        for row in reader:
            # Handle potential spaces or quotes in keys
            date_str = row.get("Date") or row.get('"Date"')
            price_raw = row.get("Price") or row.get('"Price"')
            
            if not date_str or not price_raw:
                continue

            price_usd = float(price_raw.replace(",", "").replace('"', ''))
            
            # Format date: 01/30/2026 -> 2026-01-30 00:00:00
            dt = datetime.strptime(date_str, "%m/%d/%Y")
            timestamp = dt.strftime("%Y-%m-%d %H:%M:%S")
            
            # Convert to MYR/g
            myr_per_g = round((price_usd / 31.1035) * USD_MYR_RATE, 2)
            
            world_gold_entries.append({
                "timestamp": timestamp,
                "merchant": "world_gold",
                "item": "999",
                "sell": myr_per_g,
                "buy": myr_per_g,
                "spread": 0.0
            })

    # Append or write to output file
    file_exists = os.path.isfile(OUTPUT_FILE)
    
    # Read existing entries to avoid duplicates
    existing_timestamps = set()
    if file_exists:
        with open(OUTPUT_FILE, "r", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for row in reader:
                if row["merchant"] == "world_gold":
                    existing_timestamps.add(row["timestamp"])

    with open(OUTPUT_FILE, "a", encoding="utf-8", newline='') as f:
        writer = csv.DictWriter(f, fieldnames=["timestamp", "merchant", "item", "sell", "buy", "spread"])
        if not file_exists:
            writer.writeheader()
        
        count = 0
        for entry in world_gold_entries:
            if entry["timestamp"] not in existing_timestamps:
                writer.writerow(entry)
                count += 1
                
    print(f"Added {count} new historical entries for world_gold.")

if __name__ == "__main__":
    process_history()
