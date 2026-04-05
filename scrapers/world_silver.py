import re
import time
import random
from curl_cffi import requests
from scrapers.base import GoldScraper
from utils.common import safe_float

SILVER_URL = "https://finance.yahoo.com/quote/SI=F"
USD_MYR_URL = "https://finance.yahoo.com/quote/USDMYR=X"

class WorldSilverScraper(GoldScraper):
    def get_name(self) -> str:
        return "World Silver"

    def _get_price_yahoo(self, url: str) -> float:
        try:
            # Random delay
            sleep_time = random.uniform(3, 7)
            print(f"World Silver: Sleeping for {sleep_time:.2f}s before request...")
            time.sleep(sleep_time)

            r = requests.get(url, impersonate="chrome110", timeout=30)
            r.raise_for_status()
            
            # Using regex for price extraction
            m = re.search(r'data-field="regularMarketPrice"[^>]*value="([\d,.]+)"', r.text)
            if m:
                return safe_float(m.group(1))
                
            return 0.0
        except Exception as e:
            print(f"World Silver: Error scraping {url}: {e}")
            return 0.0

    def scrape(self) -> tuple[dict, str | None]:
        silver_usd = self._get_price_yahoo(SILVER_URL)
        usd_myr = self._get_price_yahoo(USD_MYR_URL)

        if usd_myr == 0.0:
            usd_myr = 4.40

        if silver_usd == 0.0:
            return {}, None

        # 1 oz = 31.1035 grams
        myr_per_g = (silver_usd / 31.1035) * usd_myr

        items = {
            "Silver": {
                "sell": round(myr_per_g, 2),
                "buy": round(myr_per_g, 2),
                "spread": 0.0,
            },
            "USD/oz": {
                "sell": round(silver_usd, 2),
                "buy": round(silver_usd, 2),
                "spread": 0.0,
            }
        }

        from datetime import datetime
        last_updated = datetime.now().strftime("%d %b %y %H:%M")

        return items, last_updated
