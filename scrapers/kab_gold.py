
import requests
import re
from .base import GoldScraper

class KabGoldScraper(GoldScraper):
    def get_name(self) -> str:
        return "KAB Gold"

    def scrape(self) -> tuple[dict, str | None]:
        url_products = "https://app.kabgold.my/product"
        url_api = "https://app.kabgold.my/product/update-price"
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
            "X-Requested-With": "XMLHttpRequest"
        }

        # 1. Get Product Page to find IDs and Names
        # We need names to map IDs to readable labels
        try:
            r = requests.get(url_products, headers=headers, timeout=15)
            r.raise_for_status()
            html = r.text
        except Exception as e:
            print(f"KAB Gold: Failed to fetch product page: {e}")
            return {}, None

        # Extract IDs and mapping to names if possible?
        # The probe showed just finding IDs. 
        # But looking at JSON response, we don't get names, only IDs.
        # So we must parse names from HTML or map them.
        # HTML: <a ... href="product/view/182">gold bar 1g raja perlis</a>
        # Let's extract (id, name) from HTML.
        
        # Regex to find: href="product/view/(\d+)">([^<]+)</a>
        # Note: The HTML might be messy, let's try a robust regex.
        # In the dump: <a class="text-reset text-decoration-underline" href="product/view/192">kab gold logo collar pin</a>
        
        product_map = {}
        matches = re.findall(r'href="product/view/(\d+)">([^<]+)</a>', html)
        for pid, pname in matches:
            product_map[pid] = pname.strip().title()

        # Also find IDs from data-id if they are missing from links (unlikely but possible)
        pricing_ids = set(re.findall(r'data-id="(\d+)"', html))
        
        # 2. Call API
        if not pricing_ids:
            return {}, None

        params = {}
        for i in pricing_ids:
            params[f"ids[{i}]"] = "0"

        try:
            r_api = requests.get(url_api, headers=headers, params=params, timeout=15)
            r_api.raise_for_status()
            data = r_api.json()
        except Exception as e:
            print(f"KAB Gold: Failed to fetch API: {e}")
            return {}, None

        # 3. Format Output
        gold_items = {}
        for item in data:
            pid = str(item.get("id"))
            if not pid:
                continue
                
            name = product_map.get(pid, f"Product {pid}")
            
            # Simple filter: exclude non-gold items based on name keywords if needed
            # For now, include everything that looks like a gold bar/coin or has valid prices
            # Woven bag has price_buy: "N/A"
            
            price_sell_str = str(item.get("price_sell", "0")).replace(",", "").strip()
            price_buy_str = str(item.get("price_buy", "N/A")).replace(",", "").strip()

            if price_buy_str == "N/A":
                continue # Skip items we can't sell back (likely merch)

            try:
                price_sell = float(price_sell_str)
                price_buy = float(price_buy_str)
            except ValueError:
                continue

            # Standardize some names
            # "Gold Bar 1g 2025" -> "1 g" ? 
            # The existing scrapers use "999", "916" keys.
            # But KAB is a product list. We will result keys as product names.
            
            gold_items[name] = {
                "sell": price_sell,
                "buy": price_buy,
                "spread": round(price_sell - price_buy, 2)
            }

        # Last updated? The API doesn't return it.
        # We can use current time or None. 
        # The base class doc says "26 Jan 2026 09:30:00" format.
        # Since we fetch live, we can assume "Now" or just None.
        
        return gold_items, None
