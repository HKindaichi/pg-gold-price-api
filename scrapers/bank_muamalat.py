
import re
from datetime import datetime
from bs4 import BeautifulSoup
from scrapers.base import GoldScraper
from curl_cffi import requests

class BankMuamalatScraper(GoldScraper):
    def get_name(self) -> str:
        return "EasiGold"

    def scrape(self) -> tuple[dict, str | None]:
        # Target URL from user screenshot
        url = "https://www.muamalat.com.my/investment/personal/wealth-creation-accumulation/gold-i/"
        
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            "Referer": "https://www.google.com/"
        }

        try:
            r = requests.get(url, impersonate="chrome120", headers=headers, timeout=30)
            if r.status_code != 200:
                print(f"Bank Muamalat: Status {r.status_code}")
                return {}, None

            soup = BeautifulSoup(r.text, "html.parser")
            
            gold_items = {}
            
            # Helper to extract price from text e.g. "RM 630.007"
            def extract_price(text):
                clean = text.replace("RM", "").replace(",", "").strip()
                return float(clean)

            # Strategy: Find row with "EasiGold" and "RM15,000 and more"
            found_data = False
            
            for row in soup.find_all("tr"):
                text = row.get_text(" ", strip=True)
                # User requested "RM15,000 and more" dataset for 999
                if "EasiGold" in text and "more" in text and "15,000" in text:
                    cols = row.find_all("td")
                    if len(cols) >= 3:
                        # Col 0 = Name, Col 1 = Bank Sell, Col 2 = Bank Buy
                        try:
                            sell_str = cols[1].get_text(strip=True)
                            buy_str = cols[2].get_text(strip=True)
                            
                            price_sell = extract_price(sell_str)
                            price_buy = extract_price(buy_str)
                            
                            gold_items["999"] = {
                                "sell": price_sell,
                                "buy": price_buy,
                                "spread": round(price_sell - price_buy, 2)
                            }
                            found_data = True
                            break
                        except Exception as e:
                            print(f"Bank Muamalat: Parse Error - {e}")

            if not found_data:
                # If valid scraping fails, we might be blocked or URL is wrong.
                # Inspecting homepage might fail if it's dynamic.
                # Fallback: Check if there's a specific 'rates' iframe or JSON embedded.
                print("Bank Muamalat: No EasiGold table found on homepage.")
                return {}, None

            last_updated = None
            # Try to find a date
            # "As at 02 Feb 2026" or similar
            # Look for "As at" in the page
            date_match = re.search(r"As at\s+([\d]{1,2}\s+[A-Za-z]+\s+[\d]{4})", soup.get_text())
            if date_match:
                last_updated = date_match.group(1)

            return gold_items, last_updated

        except Exception as e:
            print(f"Bank Muamalat: Error {e}")
            return {}, None
