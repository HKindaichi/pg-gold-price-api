import json
import time
import random
from curl_cffi import requests
from scrapers.base import GoldScraper
from utils.common import safe_float

API_URL = "https://query1.finance.yahoo.com/v8/finance/chart/{symbol}?interval=1m&range=1d"

class WorldSilverScraper(GoldScraper):
    def get_name(self) -> str:
        return "World Silver"

    def _get_price_api(self, symbol: str) -> float:
        try:
            url = API_URL.format(symbol=symbol)
            headers = {
                "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
            }
            # Random delay
            time.sleep(random.uniform(1, 3))
            
            r = requests.get(url, impersonate="chrome120", headers=headers, timeout=30)
            if r.status_code != 200:
                print(f"World Silver API: Status {r.status_code} for {symbol}")
                return 0.0
            
            data = r.json()
            price = data["chart"]["result"][0]["meta"]["regularMarketPrice"]
            print(f"World Silver API: Found {symbol} = {price}")
            return float(price)
        except Exception as e:
            print(f"World Silver API: Error fetching {symbol}: {e}")
            return 0.0

    def scrape(self) -> tuple[dict, str | None]:
        silver_usd = self._get_price_api("SI=F")
        usd_myr = self._get_price_api("USDMYR=X")

        if usd_myr == 0.0:
            usd_myr = 4.40

        if silver_usd == 0.0 or silver_usd > 200.0: # Sanity check: Silver shouldn't be > $200/oz
            if silver_usd > 200.0:
                print(f"World Silver: Ignoring unrealistic price ${silver_usd}")
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
