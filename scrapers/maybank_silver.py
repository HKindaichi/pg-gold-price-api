
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
            
            # Specific Header Search to avoid Intro Text
            # Intro text has "Rates for ...", Header has ONLY "Maybank Silver Investment Account"
            # Using exact string match to differentiate.
            
            target_section = soup.find("p", class_="text-medium", string="Maybank Silver Investment Account")
            
            if not target_section:
                 # Fallback: try finding any P with exact text if class missing
                 target_section = soup.find("p", string="Maybank Silver Investment Account")
            
            if target_section:
                # Find the next table directly
                table = target_section.find_next("table")
                if table:
                        # Parsing Malformed HTML: The data cells might not be in a <tr>
                        # Standard check
                        rows = table.find_all("tr")
                        data_found = False
                        
                        for row in rows:
                            cols = [c.get_text(strip=True) for c in row.find_all(["td", "th"])]
                            if len(cols) >= 3:
                                col0 = cols[0]
                                if "Date" in col0 or "Selling" in col0: 
                                    continue
                                
                                # Normal case
                                try:
                                    price_sell = float(cols[1].replace(",", ""))
                                    price_buy = float(cols[2].replace(",", ""))
                                    gold_items["Silver"] = {
                                        "sell": price_sell,
                                        "buy": price_buy,
                                        "spread": round(price_sell - price_buy, 2)
                                    }
                                    data_found = True
                                    break
                                except ValueError:
                                    continue
                        
                        # Fallback for malformed HTML (<td> not in <tr>)
                        if not data_found:
                            all_tds = table.find_all("td")
                            # Expecting 3 tds: Date, Sell, Buy
                            if len(all_tds) >= 3:
                                try:
                                    price_sell = float(all_tds[1].get_text(strip=True).replace(",", ""))
                                    price_buy = float(all_tds[2].get_text(strip=True).replace(",", ""))
                                    gold_items["Silver"] = {
                                        "sell": price_sell,
                                        "buy": price_buy,
                                        "spread": round(price_sell - price_buy, 2)
                                    }
                                except Exception as e:
                                    print(f"Maybank Silver: Malformed parse error - {e}")
                
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
