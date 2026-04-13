import csv
import os

HISTORY_PATH = "output/history.csv"
TEMP_PATH = "output/history_temp.csv"

def clean_history():
    if not os.path.exists(HISTORY_PATH):
        print("History file not found.")
        return

    cleaned_rows = 0
    total_rows = 0
    
    with open(HISTORY_PATH, "r", encoding="utf-8") as fin:
        reader = csv.reader(fin)
        header = next(reader)
        
        with open(TEMP_PATH, "w", encoding="utf-8", newline="") as fout:
            writer = csv.writer(fout)
            writer.writerow(header)
            
            for row in reader:
                total_rows += 1
                try:
                    # timestamp, merchant, item, sell, buy, spread
                    sell = float(row[3])
                    # Unrealistic price for any gold/silver per gram in MYR is anything > 10000 (currently ~600)
                    if sell > 10000:
                        cleaned_rows += 1
                        continue
                    writer.writerow(row)
                except (ValueError, IndexError):
                    writer.writerow(row)

    os.replace(TEMP_PATH, HISTORY_PATH)
    print(f"Cleaned {cleaned_rows} out of {total_rows} rows.")

if __name__ == "__main__":
    clean_history()
