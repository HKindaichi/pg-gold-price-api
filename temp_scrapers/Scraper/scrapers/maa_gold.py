
import re
from datetime import datetime
from bs4 import BeautifulSoup
from scrapers.base import GoldScraper
from curl_cffi import requests

class MaaGoldScraper(GoldScraper):
    def get_name(self) -> str:
        return "MAA Gold"

    def scrape(self) -> tuple[dict, str | None]:
        url = "https://www.maaorodesign.com/"
        
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        }

        try:
            r = requests.get(url, impersonate="chrome120", headers=headers, timeout=30)
            if r.status_code != 200:
                print(f"MAA Gold: Status {r.status_code}")
                return {}, None

            soup = BeautifulSoup(r.text, "html.parser")
            
            # Find the table with "MAA Gold" in header
            target_table = None
            for table in soup.find_all("table"):
                if table.find("th", string=re.compile("MAA Gold", re.I)):
                    target_table = table
                    break
            
            gold_items = {}
            if target_table:
                rows = target_table.find_all("tr")
                for row in rows:
                    cols = row.find_all("td")
                    if len(cols) >= 3:
                        name_cell = cols[0].get_text(strip=True)
                        if "24K" in name_cell:
                            # Sell Price (Col 1: We Sell)
                            sell_text = cols[1].get_text(strip=True).replace("RM", "").replace(",", "").strip()
                            # Buy Price (Col 2: We Buy)
                            buy_text = cols[2].get_text(strip=True).replace("RM", "").replace(",", "").strip()
                            
                            try:
                                price_sell = float(sell_text)
                                price_buy = float(buy_text)
                                
                                item_name = f"MAA Gold {name_cell}"
                                gold_items[item_name] = {
                                    "sell": price_sell,
                                    "buy": price_buy,
                                    "spread": round(price_sell - price_buy, 2)
                                }
                            except ValueError:
                                print(f"MAA Gold: Parsing error - {sell_text}, {buy_text}")

            last_updated = None
            # No explicit date found in HTML dump, "GOLD PRICE TODAY" implies valid for today.
            # We can check for a script variable or metadata if needed, but for now leave None
            # or try to find a date string if any exists.
            
            return gold_items, last_updated

        except Exception as e:
            print(f"MAA Gold: Error {e}")
            return {}, None
