import os
import requests
from bs4 import BeautifulSoup
from scrapers.base import GoldScraper
from utils.common import safe_float, spread_value

MAYBANK_GOLD_URL = "https://www.maybank2u.com.my/maybank2u/malaysia/en/personal/rates/gold_and_silver.page"

class MigaiScraper(GoldScraper):
    def get_name(self) -> str:
        return "MIGA-i"

    def scrape(self) -> tuple[dict, str | None]:
        html = self._fetch_html()
        if not html:
            return {}, None

        soup = BeautifulSoup(html, "html.parser")
        return self._parse_migai_rates(soup)

    def _fetch_html(self) -> str | None:
        """
        Attempts to fetch from URL. 
        If fails (e.g. blocked/timeout) and local file exists, falls back to local file.
        """
        # 1. Try Live Request
        try:
            # Use curl_cffi to impersonate a browser fingerprint
            from curl_cffi import requests as cffi_requests
            
            r = cffi_requests.get(
                MAYBANK_GOLD_URL, 
                impersonate="chrome110", 
                timeout=15
            )
            if r.status_code == 200:
                print("Fetched Maybank2u live data (via curl_cffi).")
                return r.text
        except Exception as e:
            print(f"Web fetch failed ({e}). Checking for local fallback...")
        
        return None

    def _parse_migai_rates(self, soup: BeautifulSoup) -> tuple[dict, str | None]:
        # Strategy:
        # 1. Look for text "Maybank Islamic Gold Account-i (MIGA-i)" which is a <p class="text-medium black ...">
        # 2. Find the *next* table.
        # 3. Look for row describing "below 100 grams".
        
        target_section = soup.find(lambda tag: tag.name == "p" and "Maybank Islamic Gold Account-i (MIGA-i)" in tag.get_text())
        if not target_section:
            print("Could not find MIGA-i section.")
            return {}, None

        # The table is in a div.table-responsive immediately following the <p>
        table_div = target_section.find_next("div", class_="table-responsive")
        if not table_div:
            return {}, None
            
        table = table_div.find("table")
        if not table:
            return {}, None

        items = {}
        for row in table.find_all("tr"):
            cols = [c.get_text(strip=True) for c in row.find_all(["td", "th"])]
            if len(cols) < 3:
                continue

            label = cols[0].lower()
            if "below 100 grams" in label:
                try:
                    sell = round(safe_float(cols[1]), 2)
                    buy = round(safe_float(cols[2]), 2)
                    
                    items = {
                        "999": {
                            "sell": sell,
                            "buy": buy,
                            "spread": spread_value(sell, buy),
                        }
                    }
                except ValueError as e:
                   print(f"Error parsing numbers: {e}")
        
        # Extract Last Updated (Effective on...)
        # It is usually a <p class="text-small">Effective on ...</p> right after the table
        last_updated_str = None
        effective_p = table_div.find_next("p", class_="text-small")
        if effective_p and "Effective on" in effective_p.get_text():
            # "Effective on 26 Jan 2026 09:38:04"
            last_updated_str = effective_p.get_text(strip=True).replace("Effective on", "").strip()

        return items, last_updated_str

    def get_manual_label(self) -> str | None:
        return None
