from bs4 import BeautifulSoup
from curl_cffi import requests as cffi_requests
from .base import GoldScraper
from utils.common import safe_float, spread_value

CIMB_EGIA_URL = "https://www.cimb.com.my/en/personal/wealth-management/investments/investment-products/e-gold-investment-account-egia.html"

class CimbEgiaScraper(GoldScraper):
    def get_name(self) -> str:
        return "CIMB e-GIA"

    def scrape(self) -> tuple[dict, str | None]:
        print(f"Fetching {self.get_name()}...")
        try:
            r = cffi_requests.get(
                CIMB_EGIA_URL, 
                impersonate="chrome110", 
                timeout=20
            )
            if r.status_code != 200:
                print(f"Failed to fetch CIMB: Status {r.status_code}")
                return {}, None
                
            return self._parse(r.text)
            
        except Exception as e:
            print(f"Error fetching CIMB: {e}")
            return {}, None

    def _parse(self, html: str) -> tuple[dict, str | None]:
        soup = BeautifulSoup(html, "html.parser")
        items = {}
        last_updated_str = None

        # 1. Parsing Prices
        # Table headers often: "Gold Type", "Bank Selling (RM/gram)", "Bank Buying (RM/gram)"
        # We need to find the table that has specific headers
        tables = soup.find_all("table")
        target_table = None
        
        for table in tables:
            headers = [th.get_text(strip=True).lower() for th in table.find_all("th")]
            if any("selling" in h and "rm/gram" in h for h in headers):
                target_table = table
                break
        
        if target_table:
            # Iterate rows
            for row in target_table.find_all("tr"):
                cols = [c.get_text(strip=True) for c in row.find_all(["td"])]
                if len(cols) < 3:
                    continue
                
                label = cols[0].lower()
                # We want "CIMB Clicks" row
                if "cimb clicks" in label:
                    try:
                        # Col 1: Selling, Col 2: Buying
                        sell = safe_float(cols[1])
                        buy = safe_float(cols[2])
                        
                        items["999"] = {
                            "sell": sell,
                            "buy": buy,
                            "spread": spread_value(sell, buy),
                        }
                    except ValueError:
                        pass
        else:
            print("CIMB Price table not found.")

        # 2. Parsing Timestamp
        # <p class="rc-description font-normal text-charcoal text-sm mb-2">
        # Last Updated: 5:10 pm, 27 Jan 2026, Tuesday
        
        desc_p = soup.find("p", class_="rc-description")
        if desc_p:
            txt = desc_p.get_text(strip=True)
            if "Last Updated:" in txt:
                last_updated_str = txt.replace("Last Updated:", "").strip()

        return items, last_updated_str
