"""
Import historical merchant prices from user-provided data
"""
import os
from datetime import datetime

OUTPUT_FILE = "output/history.csv"

# Historical data from screenshots
historical_data = {
    "biga_i": [
        {"date": "30 Jan", "sell": 706.02, "buy": 683.88},
        {"date": "29 Jan", "sell": 675.49, "buy": 653.18},
        {"date": "28 Jan", "sell": 675.49, "buy": 653.18},
        {"date": "27 Jan", "sell": 666.39, "buy": 644.96},
        {"date": "26 Jan", "sell": 666.39, "buy": 644.96},
    ],
    "public_gold": [
        {"date": "31 Jan", "sell": 674.20, "buy": 613.40},
        {"date": "30 Jan", "sell": 748.20, "buy": 681.00},
        {"date": "29 Jan", "sell": 754.00, "buy": 686.20},
        {"date": "28 Jan", "sell": 713.60, "buy": 649.40},
        {"date": "27 Jan", "sell": 701.40, "buy": 638.40},
        {"date": "26 Jan", "sell": 705.40, "buy": 642.00},
        {"date": "25 Jan", "sell": 698.80, "buy": 636.00},
    ],
    "uob": [
        {"date": "30 Jan", "sell": 657.70, "buy": 653.60},
        {"date": "29 Jan", "sell": 707.20, "buy": 703.10},
        {"date": "28 Jan", "sell": 666.30, "buy": 662.20},
        {"date": "27 Jan", "sell": 650.50, "buy": 646.40},
        {"date": "26 Jan", "sell": 650.30, "buy": 646.20},
    ],
    "cimb_e_gia": [
        {"date": "30 Jan", "sell": 663.50, "buy": 656.40},
        {"date": "29 Jan", "sell": 703.10, "buy": 696.00},
        {"date": "28 Jan", "sell": 661.20, "buy": 654.10},
        {"date": "27 Jan", "sell": 648.90, "buy": 641.80},
        {"date": "26 Jan", "sell": 651.10, "buy": 644.00},
    ],
    "miga_i": [
        {"date": "30 Jan", "sell": 698.44, "buy": 684.20},
        {"date": "29 Jan", "sell": 705.91, "buy": 691.56},
        {"date": "28 Jan", "sell": 664.76, "buy": 649.74},
        {"date": "27 Jan", "sell": 657.52, "buy": 643.04},
        {"date": "26 Jan", "sell": 657.69, "buy": 643.80},
    ],
}

def parse_date(date_str):
    """Convert 'DD MMM' to '2026-01-DD 00:00:00'"""
    day, month = date_str.split()
    # All data is from Jan 2026
    return f"2026-01-{day.zfill(2)} 12:00:00"

def import_historical_data():
    # Read existing data to avoid duplicates
    existing = set()
    if os.path.exists(OUTPUT_FILE):
        with open(OUTPUT_FILE, "r", encoding="utf-8") as f:
            for line in f:
                if line.startswith("timestamp"):
                    continue
                parts = line.strip().split(",")
                if len(parts) >= 3:
                    key = (parts[0], parts[1], parts[2])  # timestamp, merchant, item
                    existing.add(key)

    new_count = 0
    with open(OUTPUT_FILE, "a", encoding="utf-8") as f:
        for merchant_id, prices in historical_data.items():
            for entry in prices:
                timestamp = parse_date(entry["date"])
                sell = entry["sell"]
                buy = entry["buy"]
                spread = round(sell - buy, 2)
                
                # All entries are for 999 purity
                item = "999"
                
                key = (timestamp, merchant_id, item)
                if key not in existing:
                    f.write(f"{timestamp},{merchant_id},{item},{sell},{buy},{spread}\n")
                    new_count += 1
                    print(f"Added: {merchant_id} {entry['date']} - Sell: {sell}, Buy: {buy}")

    print(f"\n✅ Added {new_count} new historical entries")

if __name__ == "__main__":
    import_historical_data()
