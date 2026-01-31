import re
import requests
from scrapers.base import GoldScraper
from utils.common import safe_float

XAG_USD_URL = "https://www.investing.com/currencies/xag-usd"
USD_MYR_URL = "https://www.investing.com/currencies/usd-myr"

class WorldSilverScraper(GoldScraper):
    def get_name(self) -> str:
        return "World Silver"

    def _get_price(self, url: str) -> float:
        try:
            r = requests.get(
                url,
                timeout=25,
                headers={
                    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
                    "Accept-Language": "en-US,en;q=0.9",
                },
            )
            r.raise_for_status()
            html = r.text
            
            # Common patterns on Investing.com for price
            # <span class="text-2xl" data-test="instrument-price-last">29.456</span>
            m = re.search(r'data-test="instrument-price-last"[^>]*>([\d,.]+)<', html)
            if m:
                return safe_float(m.group(1))
            
            # Fallback regex for numbers near the title
            m = re.search(r'last_last">([\d,.]+)<', html)
            if m:
                return safe_float(m.group(1))
                
            return 0.0
        except Exception as e:
            print(f"Error scraping {url}: {e}")
            return 0.0

    def scrape(self) -> tuple[dict, str | None]:
        xag_usd = self._get_price(XAG_USD_URL)
        usd_myr = self._get_price(USD_MYR_URL)

        if usd_myr == 0.0:
            usd_myr = 4.40  # Reasonable fallback for early 2026 scenario

        if xag_usd == 0.0:
            return {}, None

        # Convert USD/oz to MYR/g
        # 1 oz = 31.1035 grams
        myr_per_g = (xag_usd / 31.1035) * usd_myr

        items = {
            "Silver": {
                "sell": round(myr_per_g, 2),
                "buy": round(myr_per_g, 2),
                "spread": 0.0,
            }
        }

        # Last updated from system time since it's "Live"
        from datetime import datetime
        last_updated = datetime.now().strftime("%d %b %y %H:%M")

        return items, last_updated
