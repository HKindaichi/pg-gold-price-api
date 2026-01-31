
import requests
import csv
from io import StringIO
from .base import GoldScraper

class UobScraper(GoldScraper):
    def get_name(self) -> str:
        return "UOB"

    def scrape(self) -> tuple[dict, str | None]:
        url = "https://www.uob.com.my/wsm/stayinformed.do?path=gia"
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
        }

        try:
            r = requests.get(url, headers=headers, timeout=15)
            r.raise_for_status()
            csv_text = r.text
        except Exception as e:
            print(f"UOB: Failed to fetch CSV: {e}")
            return {}, None

        gold_items = {}
        last_updated = None

        try:
            # Parse CSV
            # CSV format: ITEM,PRODUCT,UNIT,SELLING,BUYING,DATE,TIME
            # Note: The raw text might have empty lines at the end
            f = StringIO(csv_text)
            reader = csv.DictReader(f)
            
            for row in reader:
                # ITEM: GOLD SAVINGS ACCOUNT
                # PRODUCT: 1 GM
                # UNIT: 650.40 (Bank Selling) -> key 'sell'
                # SELLING: 646.30 (Bank Buying) -> key 'buy'
                # DATE: 27/01/2026
                # TIME: 27/01/2026 15:39
                
                name = row.get("ITEM", "").strip().title()
                product = row.get("PRODUCT", "").strip().title()
                
                # Combine name and product if needed, e.g. "Gold Savings Account (1 Gm)"
                # Or just use "Gold Savings Account" if 1 GM is the base unit.
                # The "1 Kilo" logic likely has different price per gram or just huge price?
                
                try:
                    price_sell = float(row.get("UNIT", "0"))
                    price_buy = float(row.get("SELLING", "0"))
                    
                    # Update date
                    # Accessing 'DATE' key might be tricky if CSV parser is strict and there is trailing comma issue
                    # Looking at probe output: ITEM,PRODUCT,UNIT,SELLING,BUYING,DATE,TIME
                    # Headers are 7. 
                    # Row: GOLD SAVINGS ACCOUNT,1 GM,650.40,646.30,27/01/2026,27/01/2026 15:39
                    # It seems 'BUYING' in header maps to '27/01/2026' value? 
                    # Re-check probe output
                    # ITEM,PRODUCT,UNIT,SELLING,BUYING,DATE,TIME
                    # GOLD SAVINGS ACCOUNT,1 GM,650.40,646.30,27/01/2026,27/01/2026 15:39
                    
                    # There are 7 headers, but only 6 values!
                    # "BUYING" header has value "27/01/2026" ?? No.
                    # Value index 4 (0-based) is "27/01/2026". Header index 4 is "BUYING".
                    # So "SELLING" (index 3) is 646.30.
                    # "UNIT" (index 2) is 650.40.
                    
                    # Wait, where is the "Bank Buying" price?
                    # The probe showed:
                    # Col 3: 650.40
                    # Col 4: 646.30
                    # Col 5: 27/01/2026
                    # Col 6: 27/01/2026 15:39
                    
                    # If I use DictReader, it maps Header -> Value.
                    # UNIT -> 650.40
                    # SELLING -> 646.30
                    # BUYING -> 27/01/2026 (Wait, this is date?)
                    # DATE -> 27/01/2026 15:39 (Time?)
                    # TIME -> None/Empty
                    
                    # So "Bank Buying" price is correctly under "SELLING" header?
                    # And "Bank Selling" price is under "UNIT" header?
                    
                    # Let's double check HTML column order again.
                    # HTML: Item, Size, Bank Selling (RM), Bank Buying (RM)
                    # JS: output_json[i].UNIT -> Cols 3 (Bank Selling)
                    # JS: output_json[i].SELLING -> Cols 4 (Bank Buying)
                    
                    # So my previous logic was correct:
                    # UNIT = Bank Selling (User Buy) -> sell
                    # SELLING = Bank Buying (User Sell) -> buy
                    
                    # The CSV header "BUYING" seems unused or misaligned?
                    # "BUYING" column in CSV contains the DATE?
                    # "DATE" column contains TIME?
                    # "TIME" is empty.
                    
                    # Yup, standard CSV misalignment.
                    # I will rely on UNIT and SELLING keys.
                    
                    timestamp = row.get("DATE") # "27/01/2026 15:39" (mapped from existing "DATE" header potentially having time?)
                    # Actually if "BUYING" has Date, checking "DATE" header for Time might be correct.
                    # Row index 5 is "27/01/2026 15:39". Header index 5 is "DATE".
                    
                    if timestamp:
                        last_updated = timestamp
                    
                except ValueError:
                    continue
                    
                full_name = f"{name} ({product})"
                
                gold_items[full_name] = {
                    "sell": price_sell,
                    "buy": price_buy,
                    "spread": round(price_sell - price_buy, 2)
                }
                
                # Align with App's 999 filter
                if "1 Gm" in product:
                    gold_items["999"] = gold_items[full_name]
                
        except Exception as e:
            print(f"UOB: Parsing error: {e}")
            return {}, None

        return gold_items, last_updated
