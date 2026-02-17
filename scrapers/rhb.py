from scrapers.base import GoldScraper
import requests
from bs4 import BeautifulSoup
from utils.common import safe_float

class RhbScraper(GoldScraper):
    def get_name(self):
        return "RHB"

    def scrape(self):
        # URL for RHB Precious Metal Exchange
        url = "https://www.rhbgroup.com/treasury-rates/precious-metal-exchange/index.html"
        
        print(f"Scraping {self.get_name()} from {url}...")
        
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
        }

        try:
            response = requests.get(url, headers=headers, timeout=15)
            response.raise_for_status()
            
            soup = BeautifulSoup(response.content, "html.parser")
            
            items = {}
            
            # Find the table rows
            # Based on structure, look for 'GLD' and 'SLV'
            # Usually in a table with class or just generic table
            
            tables = soup.find_all("table")
            target_table = None
            
            # Heuristic: Find table containing "Bank Sell"
            for table in tables:
                if "Bank Sell" in table.get_text():
                    target_table = table
                    break
            
            if not target_table:
                print("Could not find RHB exchange rate table.")
                return {}

            rows = target_table.find_all("tr")
            
            for row in rows:
                cols = row.find_all("td")
                if not cols:
                    continue
                
                row_text = [c.get_text(strip=True) for c in cols]
                # Expected format based on image:
                # [GLD, Paper Gold, 1, 630.1112, 623.3701]
                # [SLV, Paper Silver, 1, 9.9687, 9.2958]
                
                if len(row_text) < 4:
                    continue
                
                code = row_text[0]
                
                if "GLD" in code:
                    # Gold 999
                    # Sell is usually the higher number (Bank Sell to customer)
                    # From image: Bank Sell (630) > Bank Buy (623)
                    # Column index might vary, typically: Name, Unit, Sell, Buy
                    # Let's parse strictly
                    
                    sell_str = row_text[-2] # Second to last
                    buy_str = row_text[-1]  # Last
                    
                    sell_price = safe_float(sell_str)
                    buy_price = safe_float(buy_str)
                    
                    if sell_price and buy_price:
                        items["999"] = {
                            "sell": sell_price,
                            "buy": buy_price,
                            "spread": round(sell_price - buy_price, 2)
                        }

                elif "SLV" in code:
                    # Silver
                    sell_str = row_text[-2]
                    buy_str = row_text[-1]
                    
                    sell_price = safe_float(sell_str)
                    buy_price = safe_float(buy_str)
                    
                    if sell_price and buy_price:
                        items["Silver"] = {
                            "sell": sell_price,
                            "buy": buy_price,
                            "spread": round(sell_price - buy_price, 2)
                        }

            return items
            
        except Exception as e:
            print(f"Error scraping RHB: {e}")
            return {}
