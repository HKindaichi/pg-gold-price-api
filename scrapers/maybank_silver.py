
from bs4 import BeautifulSoup
from .base import GoldScraper

class MaybankSilverScraper(GoldScraper):
    def get_name(self) -> str:
        return "Maybank Silver"

    def scrape(self) -> tuple[dict, str | None]:
        url = "https://www.maybank2u.com.my/maybank2u/malaysia/en/personal/rates/gold_and_silver.page"
        
        try:
            from curl_cffi import requests as cffi_requests
            r = cffi_requests.get(
                url, 
                impersonate="chrome110", 
                timeout=30
            )
            if r.status_code != 200:
                print(f"Maybank Silver: HTTP {r.status_code}")
                return {}, None
            
            html = r.text
            soup = BeautifulSoup(html, "html.parser")
            
        except Exception as e:
            print(f"Maybank Silver: Fetch Error - {e}")
            return {}, None

        gold_items = {}
        last_updated = None

        try:
            # Strategy: Look for the specific header text "Maybank Silver Investment Account"
            # It's likely a <p> or <div class="text_title"> or similar.
            # Based on MIGA-i structure, it's likely a <p> tag.
            
            target_section = soup.find(lambda tag: tag.name == "p" and "Maybank Silver Investment Account" in tag.get_text())
            
            if not target_section:
                # Try finding just by string matching in the whole soup if exact tag match fails
                # The text in screenshot is "Maybank Silver Investment Account"
                header_text = soup.find(string=lambda t: t and "Maybank Silver Investment Account" in t)
                if header_text:
                    target_section = header_text.parent
            
            if target_section:
                # Find the next table directly
                table = target_section.find_next("table")
                if table:
                        # Parse rows. 
                        # Header: Date, Selling (RM/g), Buying (RM/g)
                        rows = table.find_all("tr")
                        for row in rows:
                            cols = [c.get_text(strip=True) for c in row.find_all(["td", "th"])]
                            print(f"DEBUG ROW: {cols}")
                            if len(cols) >= 3:
                                col0 = cols[0]
                                if "Date" in col0 or "Selling" in col0: 
                                    print("Skipping header")
                                    continue
                                
                                # Data row: "02 Feb 2026", "14.55", "13.40"
                                try:
                                    print(f"Parsing: {cols[1]}, {cols[2]}")
                                    price_sell = float(cols[1].replace(",", ""))
                                    price_buy = float(cols[2].replace(",", ""))
                                    
                                    gold_items["Silver"] = {
                                        "sell": price_sell,
                                        "buy": price_buy,
                                        "spread": round(price_sell - price_buy, 2)
                                    }
                                    break # Take first row
                                except ValueError:
                                    continue
                
                # Timestamp: "Effective on 02 Feb 2026 02:11 PM"
                # Usually in a <p class="text-small"> after the table
                effective_p = None
                if table:
                    effective_p = table.find_next("p", class_="text-small")
                
                if effective_p and "Effective on" in effective_p.get_text():
                    last_updated = effective_p.get_text(strip=True).replace("Effective on", "").strip()


        except Exception as e:
            print(f"Maybank Silver: Parse Error - {e}")
            return {}, None

        return gold_items, last_updated
