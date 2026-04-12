import re
import time
import random
from curl_cffi import requests
from bs4 import BeautifulSoup
from scrapers.base import GoldScraper
from utils.common import safe_float

GOLD_URL = "https://finance.yahoo.com/quote/GC=F"
USD_MYR_URL = "https://finance.yahoo.com/quote/USDMYR=X"

class WorldGoldScraper(GoldScraper):
    def get_name(self) -> str:
        return "World Gold"

    def _get_price_yahoo(self, url: str) -> float:
        try:
            # Random delay to look more human
            sleep_time = random.uniform(3, 7)
            print(f"World Gold: Sleeping for {sleep_time:.2f}s before request...")
            time.sleep(sleep_time)

            r = requests.get(url, impersonate="chrome110", timeout=30)
            r.raise_for_status()
            
            # Yahoo Finance uses <fin-streamer data-field="regularMarketPrice" ... value="2400.00">
            # Using regex for better stability against minor HTML changes
            m = re.search(r'data-field="regularMarketPrice"[^>]*value="([\d,.]+)"', r.text)
            if m:
                return safe_float(m.group(1))
            
            # Fallback if value attribute is missing
            soup = BeautifulSoup(r.text, 'html.parser')
            el = soup.find('fin-streamer', {'data-field': 'regularMarketPrice'})
            if el and el.get('value'):
                return safe_float(el.get('value'))
                
            return 0.0
        except Exception as e:
            print(f"World Gold: Error scraping {url}: {e}")
            return 0.0

    def scrape(self) -> tuple[dict, str | None]:
        gold_usd = self._get_price_yahoo(GOLD_URL)
        usd_myr = self._get_price_yahoo(USD_MYR_URL)

        if usd_myr == 0.0:
            usd_myr = 4.40  # Fallback

        if gold_usd == 0.0 or gold_usd > 4000.0: # Sanity check: Gold shouldn't be > $4000/oz suddenly
            if gold_usd > 4000.0:
                print(f"World Gold: Ignoring unrealistic price ${gold_usd}")
            return {}, None

        # 1 oz = 31.1035 grams
        myr_per_g = (gold_usd / 31.1035) * usd_myr

        items = {
            "999": {
                "sell": round(myr_per_g, 2),
                "buy": round(myr_per_g, 2),
                "spread": 0.0,
            },
            "USD/oz": {
                "sell": round(gold_usd, 2),
                "buy": round(gold_usd, 2),
                "spread": 0.0,
            }
        }

        from datetime import datetime
        last_updated = datetime.now().strftime("%d %b %y %H:%M")

        return items, last_updated

if __name__ == "__main__":
    scraper = WorldGoldScraper()
    items, updated = scraper.scrape()
    print(f"Items: {items}")
    print(f"Updated: {updated}")
