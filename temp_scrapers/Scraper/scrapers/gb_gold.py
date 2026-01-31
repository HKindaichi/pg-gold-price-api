
from datetime import datetime
from scrapers.base import GoldScraper
from curl_cffi import requests
import json

class GbGoldScraper(GoldScraper):
    def get_name(self) -> str:
        return "GB Gold"

    def scrape(self) -> tuple[dict, str | None]:
        url = "https://gbgold.my/api/v3/price/gwa"
        
        try:
            r = requests.get(url, impersonate="chrome110", timeout=30)
            if r.status_code != 200:
                print(f"GB Gold: Status {r.status_code}")
                return {}, None
                
            data = r.json()
            if not data.get("success"):
                print("GB Gold: API returned success=false")
                return {}, None
                
            price_data = data.get("data", {})
            
            # Extract prices
            # The API returns strings like "698.00"
            price_sell = float(price_data.get("sell_price", "0"))
            price_buy = float(price_data.get("buy_price", "0"))
            
            # Last updated
            # Format: "28-01-2026 08:45:02"
            last_updated_str = price_data.get("last_updated")
            last_updated = None
            if last_updated_str:
                try:
                    dt = datetime.strptime(last_updated_str, "%d-%m-%Y %H:%M:%S")
                    # Assuming local time (Malaysia is UTC+8), but we store naive or use helper if needed.
                    # For now, keep as string or convertible object.
                    # The base class expects a string or None, usually just passed through.
                    last_updated = last_updated_str
                except ValueError:
                    pass

            item_name = "Gold Wa'diah Account (GWA)"
            
            gold_items = {
                item_name: {
                    "sell": price_sell,
                    "buy": price_buy,
                    "spread": round(price_sell - price_buy, 2)
                }
            }
            
            return gold_items, last_updated
            
        except Exception as e:
            print(f"GB Gold: Error {e}")
            return {}, None
