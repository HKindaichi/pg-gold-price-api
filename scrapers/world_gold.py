import json
import time
import random
from curl_cffi import requests
from scrapers.base import GoldScraper
from utils.common import safe_float

API_URL = "https://query1.finance.yahoo.com/v8/finance/chart/{symbol}?interval=1m&range=1d"

class WorldGoldScraper(GoldScraper):
    def get_name(self) -> str:
        return "World Gold"

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
                print(f"World Gold API: Status {r.status_code} for {symbol}")
                return 0.0
            
            data = r.json()
            price = data["chart"]["result"][0]["meta"]["regularMarketPrice"]
            print(f"World Gold API: Found {symbol} = {price}")
            return float(price)
        except Exception as e:
            print(f"World Gold API: Error fetching {symbol}: {e}")
            return 0.0

    def scrape(self) -> tuple[dict, str | None]:
        gold_usd = self._get_price_api("GC=F")
        usd_myr = self._get_price_api("USDMYR=X")

        if usd_myr == 0.0:
            usd_myr = 4.40  # Fallback

        if gold_usd == 0.0 or gold_usd > 6000.0: # Sanity check: Gold shouldn't be > $6000/oz suddenly
            if gold_usd > 6000.0:
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
