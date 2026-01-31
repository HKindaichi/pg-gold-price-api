import json
import os
import re
from datetime import datetime
from zoneinfo import ZoneInfo

from utils.common import now_my, format_updated_label, read_json_file
from scrapers.base import GoldScraper
from scrapers.public_gold import PublicGoldScraper
from scrapers.miga_i import MigaiScraper
from scrapers.cimb_egia import CimbEgiaScraper
from scrapers.kab_gold import KabGoldScraper
from scrapers.uob import UobScraper
from scrapers.gb_gold import GbGoldScraper
from scrapers.bank_islam import BigaScraper
from scrapers.maa_gold import MaaGoldScraper
from scrapers.world_gold import WorldGoldScraper
from scrapers.world_silver import WorldSilverScraper

# =========================
# Config
# =========================
OUTPUT_PATH = os.path.join("output", "latest.json")
HISTORY_CSV_PATH = os.path.join("output", "history.csv")

def write_output(payload: dict):
    os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)
    
    # 1. Write latest.json
    with open(OUTPUT_PATH, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=2)

    # 2. Append to history.csv (Smart Mode: Skip duplicates)
    file_exists = os.path.isfile(HISTORY_CSV_PATH)
    timestamp = now_my().strftime("%Y-%m-%d %H:%M:%S")

    # Read last recorded prices to avoid consecutive duplicates
    last_recorded = {}
    if file_exists:
        try:
            with open(HISTORY_CSV_PATH, "r", encoding="utf-8") as f:
                import csv
                reader = csv.reader(f)
                for row in reader:
                    if len(row) >= 5 and row[0] != "timestamp":
                        # timestamp, merchant, item, sell, buy, spread
                        m_id = row[1]
                        item_key = row[2]
                        try:
                            s_val = float(row[3])
                            b_val = float(row[4])
                            last_recorded[(m_id, item_key)] = (s_val, b_val)
                        except ValueError:
                            continue
        except Exception as e:
            print(f"Warning reading history for deduplication: {e}")

    with open(HISTORY_CSV_PATH, "a", encoding="utf-8") as f:
        if not file_exists:
            f.write("timestamp,merchant,item,sell,buy,spread\n")
        
        for merchant in payload.get("merchants", []):
            m_id = merchant["id"]
            items = merchant.get("items", {})
            for item_key, item_data in items.items():
                sell = float(item_data.get("sell", 0))
                buy = float(item_data.get("buy", 0))
                spread = item_data.get("spread", 0)

                # Check for duplicate
                last_entry = last_recorded.get((m_id, item_key))
                
                # Check if price changed
                if last_entry:
                    last_sell, last_buy = last_entry
                    if last_sell == sell and last_buy == buy:
                        # Exact same price as last record, SKIP
                        continue
                
                # If new or changed, write it
                f.write(f"{timestamp},{m_id},{item_key},{sell},{buy},{spread}\n")
                print(f"Saved new history for {m_id} - {item_key}")

def main():
    print("Starting Gold Scraper Job...")
    
    # 1. Register all scrapers
    scrapers: list[GoldScraper] = [
        PublicGoldScraper(),
        MigaiScraper(),
        CimbEgiaScraper(),
        KabGoldScraper(),
        UobScraper(),
        GbGoldScraper(),
        BigaScraper(),
        MaaGoldScraper(),
        WorldGoldScraper(),
        WorldSilverScraper(),
    ]

    merchants = []
    
    # 2. Run each scraper
    for scraper in scrapers:
        print(f"Running scraper: {scraper.get_name()}...")
        try:
            result = scraper.scrape()
            if isinstance(result, tuple):
                items, last_updated = result
            else:
                items, last_updated = result, None

            if items:
                m_id = scraper.get_name().lower().replace(" ", "_").replace("-", "_")
                merchant_data = {
                    "id": m_id,
                    "name": scraper.get_name(),
                    "items": items
                }
                if last_updated:
                    merchant_data["last_updated"] = last_updated
                merchants.append(merchant_data)

        except Exception as e:
            print(f"Error running scraper {scraper.get_name()}: {e}")

    # 3. Build Final Payload
    dt = now_my()
    updated_label = format_updated_label(dt)

    payload = {
        "updated_label": updated_label,
        "merchants": merchants,
    }

    # 4. Mandatory check for Public Gold
    has_pg = any(m.get("id") == "public_gold" for m in merchants)
    if not has_pg:
        print("WARNING: Public Gold missing from output.")

    # 5. Write to file
    write_output(payload)
    print(f"✅ Wrote {OUTPUT_PATH} and {HISTORY_CSV_PATH} with {len(merchants)} merchants.")

if __name__ == "__main__":
    main()
