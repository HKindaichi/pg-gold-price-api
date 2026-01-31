
import re
from datetime import datetime
from bs4 import BeautifulSoup
from scrapers.base import GoldScraper
from curl_cffi import requests

class BigaScraper(GoldScraper):
    def get_name(self) -> str:
        return "BIGA-i"

    def scrape(self) -> tuple[dict, str | None]:
        url = "https://www.bankislam.com/personal-banking/bank-islam-gold-account-biga-i/"
        
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
             "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
        }

        try:
            r = requests.get(url, impersonate="chrome120", headers=headers, timeout=30)
            if r.status_code != 200:
                print(f"Bank Islam: Status {r.status_code}")
                return {}, None

            soup = BeautifulSoup(r.text, "html.parser")
            
            # Find the table with "Bank Sell (MYR)"
            price_sell = 0.0
            price_buy = 0.0
            
            # Look for headers
            sell_header = soup.find("strong", string=re.compile("Bank Sell", re.I))
            if sell_header:
                # Go up to find the table or row
                # Structure: th > p > strong > Bank Sell
                # We need the corresponding data cells in the tbody
                
                # Find the main table containing this header
                table = sell_header.find_parent("table")
                if table:
                    rows = table.find_all("tr")
                    # Assuming data is in the second row (index 1) or first row of body
                    # The HTML shows a thead and tbody.
                    tbody = table.find("tbody")
                    if tbody:
                        data_row = tbody.find("tr")
                        if data_row:
                            cols = data_row.find_all("td")
                            if len(cols) >= 2:
                                # Sell Price
                                sell_text = cols[0].get_text(strip=True).replace("RM", "").replace(",", "")
                                # Buy Price
                                buy_text = cols[1].get_text(strip=True).replace("RM", "").replace(",", "")
                                
                                try:
                                    price_sell = float(sell_text)
                                    price_buy = float(buy_text)
                                except ValueError:
                                    print(f"Bank Islam: Parsing error for prices: {sell_text}, {buy_text}")

            # Last Updated
            # <p><strong>27 January 2026; 9:00am</strong></p>
            # Look for "Effective update" and take the next element or nearby strong tag
            last_updated = None
            update_label = soup.find(string=re.compile("Effective update", re.I))
            if update_label:
                # Try to find the date in the next paragraph or strong tag
                # based on HTML dump: 
                # <p>Effective update:</p><p></p><h6><p><strong>27 January 2026; 9:00am</strong></p></h6>
                
                # Let's look for a date pattern nearby
                container = update_label.find_parent("div") # The table is inside a div usually, or just look generally
                if container:
                    date_text_match = container.find_next("strong", string=re.compile(r"\d+\s+[A-Za-z]+\s+\d{4}", re.I))
                    if date_text_match:
                        last_updated = date_text_match.get_text(strip=True)
            
            # Fallback for date if specific hierarchy fails: search for date pattern directly
            if not last_updated:
                 # Regex for "DD Month YYYY; HH:MMam/pm"
                 date_pattern = re.compile(r"\d{1,2}\s+[A-Za-z]+\s+\d{4}.*\d{1,2}:\d{2}\s?[ap]m", re.I)
                 found_date = soup.find(string=date_pattern)
                 if found_date:
                     last_updated = found_date.strip()

            gold_items = {
                "999": {
                    "sell": price_sell,
                    "buy": price_buy,
                    "spread": round(price_sell - price_buy, 2)
                }
            }

            return gold_items, last_updated

        except Exception as e:
            print(f"Bank Islam: Error {e}")
            return {}, None
