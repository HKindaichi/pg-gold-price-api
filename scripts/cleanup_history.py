"""
Cleanup history.csv to remove consecutive duplicate entries (same merchant, same prices).
This helps declutter the chart and table.
"""
import csv
import os
from datetime import datetime

INPUT_FILE = "output/history.csv"
OUTPUT_FILE = "output/history_cleaned.csv"

def cleanup_history():
    if not os.path.exists(INPUT_FILE):
        print(f"File {INPUT_FILE} not found.")
        return

    entries = []
    with open(INPUT_FILE, "r", encoding="utf-8") as f:
        reader = csv.reader(f)
        for row in reader:
            entries.append(row)

    print(f"Total entries before cleanup: {len(entries)}")

    # Sort by timestamp to ensure chronological order for deduplication
    # Assuming valid CSV structure: timestamp, merchant, item, sell, buy, spread
    # We need to handle potential headers if any (though standard format seems headerless or inconsistent)
    
    data_rows = []
    header = None
    
    for row in entries:
        if len(row) < 6:
            continue
        if row[0].startswith("timestamp"):
            header = row
            continue
        data_rows.append(row)

    # Sort by timestamp
    data_rows.sort(key=lambda x: x[0])

    cleaned_rows = []
    
    # Store last seen entry for each merchant to compare
    # Key: merchant_id
    last_seen = {}

    for row in data_rows:
        timestamp, merchant, item, sell, buy, spread = row
        
        # specific key to track uniqueness: merchant + item
        key = f"{merchant}_{item}"
        
        if key not in last_seen:
            cleaned_rows.append(row)
            last_seen[key] = row
        else:
            # Check if prices changed
            last_row = last_seen[key]
            last_sell = last_row[3]
            last_buy = last_row[4]
            
            # If price changed, keep it
            if sell != last_sell or buy != last_buy:
                cleaned_rows.append(row)
                last_seen[key] = row
            else:
                # Same price. 
                # Optional: Keep 1 entry per day even if price is same? 
                # For now, strictly remove consecutive duplicates to fix the "Last 10 updates" spam.
                # BUT, we might want to keep the *latest* timestamp for the same price to show freshness?
                # Actually, standard OHLC logic usually keeps all ticks, but for a simple list, distinct changes are better.
                # Let's keep duplicate ONLY if it's a different day, to show "yep, still same price today".
                
                last_ts = datetime.strptime(last_row[0], "%Y-%m-%d %H:%M:%S")
                curr_ts = datetime.strptime(timestamp, "%Y-%m-%d %H:%M:%S")
                
                if last_ts.date() != curr_ts.date():
                     cleaned_rows.append(row)
                     last_seen[key] = row
    
    print(f"Total entries after cleanup: {len(cleaned_rows)}")
    
    # Write back
    with open(INPUT_FILE, "w", encoding="utf-8", newline="") as f:
        writer = csv.writer(f)
        if header:
            writer.writerow(header)
        writer.writerows(cleaned_rows)

    print("Cleanup complete. Overwrote output/history.csv")

if __name__ == "__main__":
    cleanup_history()
