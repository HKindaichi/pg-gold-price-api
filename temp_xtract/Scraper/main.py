
import os
import json
from utils.common import now_my, format_updated_label, read_json_file
from scrapers.base import GoldScraper
from scrapers.public_gold import PublicGoldScraper
from scrapers.miga_i import MigaiScraper
from scrapers.cimb_egia import CimbEgiaScraper
from scrapers.kab_gold import KabGoldScraper
from scrapers.uob import UobScraper
from scrapers.gb_gold import GbGoldScraper
from scrapers.bank_islam import BankIslamScraper
from scrapers.maa_gold import MaaGoldScraper

OUTPUT_FILE = "output/latest.json"

def write_output(payload: dict):
    os.makedirs(os.path.dirname(OUTPUT_FILE), exist_ok=True)
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=2)

def main():
    print("Starting Gold Scraper Job...")
    # 1. Register all scrapers here
    #    You can add more scrapers to this list as you implement them.
    scrapers: list[GoldScraper] = [
        PublicGoldScraper(),
        MigaiScraper(),
        CimbEgiaScraper(),
        KabGoldScraper(),
        UobScraper(),
        GbGoldScraper(),
        BankIslamScraper(),
        MaaGoldScraper(),
    ]

    # 2. Results container
    merchants = []
    
    # 3. Helpers to track special fields
    #    We check for MIGA-i manual label to preserve the old behavior (migai_updated_label)
    migai_label = None

    # 4. Run each scraper
    for scraper in scrapers:
        print(f"Running scraper: {scraper.get_name()}...")
        try:
            # scrape() now returns (items_dict, last_updated_str)
            result = scraper.scrape()
            if isinstance(result, tuple):
                items, last_updated = result
            else:
                 # Fallback if someone didn't update their scraper yet
                items, last_updated = result, None

            if items:
                # Build merchant object
                merchant_id = scraper.get_name().lower().replace(" ", "_").replace("-", "_")
                
                merchant_data = {
                    "id": merchant_id,
                    "name": scraper.get_name(),
                    "items": items
                }
                
                # Add last_updated if available
                if last_updated:
                    merchant_data["last_updated"] = last_updated
                    
                merchants.append(merchant_data)
                
                # Special case: Check for Migai manual label (if we still supported it via file)
                if isinstance(scraper, MigaiScraper):
                     label = scraper.get_manual_label()
                     if label:
                         migai_label = label

        except Exception as e:
            print(f"Error running scraper {scraper.get_name()}: {e}")

    # 5. Build Final Payload
    dt = now_my()
    updated_label = format_updated_label(dt)

    payload = {
        "updated_label": updated_label,
        "merchants": merchants,
    }

    if migai_label:
        payload["migai_updated_label"] = migai_label

    # 6. Validation (Legacy Requirement)
    #    Ensure Public Gold is present
    has_pg = any(m.get("id") == "public_gold" for m in merchants)
    if not has_pg:
        print("WARNING: Public Gold missing from output.")
        # We can decide to raise an error here if strict validation is still needed
        # raise SystemExit("Public Gold missing. Scraper likely changed.")

    # 7. Write to file
    write_output(payload)
    print(f"Wrote {OUTPUT_FILE} with {len(merchants)} merchants.")

if __name__ == "__main__":
    main()