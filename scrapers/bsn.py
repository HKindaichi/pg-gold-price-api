
from bs4 import BeautifulSoup
from curl_cffi import requests as cffi_requests
import re
from .base import GoldScraper

class BsnScraper(GoldScraper):
    def get_name(self) -> str:
        return "MyGold-i"

    def scrape(self) -> tuple[dict, str | None]:
        url = "https://www.bsn.com.my/page/BSNMyGoldAccount-i"
        
        try:
            headers = {
                "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Safari/537.36",
                "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
                "Accept-Language": "en-US,en;q=0.9",
                "Referer": "https://www.google.com/",
                "Upgrade-Insecure-Requests": "1"
            }
            
            r = cffi_requests.get(url, headers=headers, impersonate="chrome110", timeout=30)
            if r.status_code != 200:
                return {}, None
            
            html = r.text
            soup = BeautifulSoup(html, "html.parser")
            
        except Exception as e:
            print(f"BSN: Fetch Error - {e}")
            return {}, None

        gold_items = {}
        last_updated = None

        try:
            # Global search for prices is most reliable for this site
            price_re = re.compile(r"\d{3}\.\d{2}")
            all_text = soup.get_text()
            
            found_prices = price_re.findall(all_text)
            potential = []
            for p in found_prices:
                try:
                    val = float(p.replace(",", ""))
                    if 500 < val < 900:
                        potential.append(val)
                except: continue
            
            unique_prices = sorted(list(set(potential)), reverse=True)
            
            if len(unique_prices) >= 2:
                # Based on User Screenshot: Sell 712.60, Buy 674.01
                gold_items["999"] = {
                    "sell": unique_prices[0],
                    "buy": unique_prices[1],
                    "spread": round(unique_prices[0] - unique_prices[1], 2)
                }

            # Timestamp
            update_re = re.compile(r"Effective\s+update", re.I)
            update_label = soup.find(string=update_re)
            if update_label:
                next_nodes = update_label.find_all_next(string=True, limit=15)
                for node in next_nodes:
                    text = node.strip()
                    if ("2026" in text or "2025" in text) and len(text) > 10:
                        last_updated = text
                        break

        except Exception as e:
            print(f"BSN: Parse Error - {e}")

        return gold_items, last_updated
