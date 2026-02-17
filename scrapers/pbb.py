from bs4 import BeautifulSoup
from curl_cffi import requests as cffi_requests
import re
from .base import GoldScraper

class PbbScraper(GoldScraper):
    def get_name(self) -> str:
        return "PBB"

    def scrape(self) -> tuple[dict, str | None]:
        url = "https://www.pbebank.com/en/rates-charges/gold-investment-account/"
        
        try:
            headers = {
                "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Safari/537.36",
                "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
                "Accept-Language": "en-US,en;q=0.9",
                "Referer": "https://www.google.com/",
                "Upgrade-Insecure-Requests": "1"
            }
            
            # Using curl_cffi to match other scrapers and handle Cloudflare
            r = cffi_requests.get(url, headers=headers, impersonate="chrome110", timeout=30)
            if r.status_code != 200:
                print(f"PBB: Fetch Error - Status Code {r.status_code}")
                return {}, None
            
            html = r.text
            soup = BeautifulSoup(html, "html.parser")
            
        except Exception as e:
            print(f"PBB: Fetch Error - {e}")
            return {}, None

        gold_items = {}
        last_updated = None

        try:
            # 1. Extract Timestamp
            # Example text: "Gold Investment Account as at 17 February 2026 12:01 AM"
            page_text = soup.get_text()
            timestamp_match = re.search(r"as at\s+(\d+\s+\w+\s+\d{4}\s+\d{2}:\d{2}\s+[AP]M)", page_text, re.I)
            if timestamp_match:
                last_updated = timestamp_match.group(1).strip()

            # 2. Extract Prices
            # Look for the table row that contains "1 gram"
            # Based on the screenshot, it should have Selling Price and Buying Price columns
            table = soup.find("table")
            if table:
                rows = table.find_all("tr")
                for row in rows:
                    cells = row.find_all(["td", "th"])
                    cell_texts = [c.get_text(strip=True) for c in cells]
                    
                    # Pattern for "1 gram" or similar
                    if any("1 gram" in text.lower() for text in cell_texts):
                        # Filter out non-numeric characters except decimals
                        prices = []
                        for text in cell_texts:
                            val_match = re.search(r"(\d+\.\d+)", text)
                            if val_match:
                                prices.append(float(val_match.group(1)))
                        
                        if len(prices) >= 2:
                            # Usually Sell is higher than Buy
                            sell = max(prices)
                            buy = min(prices)
                            
                            gold_items["999"] = {
                                "sell": sell,
                                "buy": buy,
                                "spread": round(sell - buy, 2)
                            }
                            break
            
            # Fallback if table parsing fails
            if not gold_items:
                gold_items, alt_last_updated = self._extract_via_regex(html)
                if not last_updated:
                    last_updated = alt_last_updated

        except Exception as e:
            print(f"PBB: Parse Error - {e}")
            # Final fallback
            if not gold_items:
                gold_items, last_updated = self._extract_via_regex(html)

        return gold_items, last_updated

    def _extract_via_regex(self, html: str) -> tuple[dict, str | None]:
        # Fallback if table parsing fails: general regex search
        gold_items = {}
        last_updated = None
        
        # 1. Extract Timestamp
        timestamp_match = re.search(r"as at\s+(\d+\s+\w+\s+\d{4}\s+\d{2}:\d{2}\s+[AP]M)", html, re.I)
        if timestamp_match:
            last_updated = timestamp_match.group(1).strip()

        # 2. Extract Prices
        price_matches = re.findall(r"(\d+\.\d{2,4})", html)
        potential_prices = []
        for p in price_matches:
            val = float(p)
            if 500 < val < 900: # Sanity check for current MYR gold prices
                potential_prices.append(val)
        
        unique_prices = sorted(list(set(potential_prices)), reverse=True)
        if len(unique_prices) >= 2:
            sell = unique_prices[0]
            buy = unique_prices[1]
            gold_items["999"] = {
                "sell": sell,
                "buy": buy,
                "spread": round(sell - buy, 2)
            }
        return gold_items, last_updated
