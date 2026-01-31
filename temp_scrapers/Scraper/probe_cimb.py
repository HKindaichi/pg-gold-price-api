
from curl_cffi import requests
from bs4 import BeautifulSoup

def probe_cimb():
    url = "https://www.cimb.com.my/en/personal/wealth-management/investments/investment-products/e-gold-investment-account-egia.html"
    print(f"Fetching {url}...")
    try:
        r = requests.get(url, impersonate="chrome110", timeout=15)
        print(f"Status: {r.status_code}")
        
        soup = BeautifulSoup(r.text, "html.parser")
        
        # Search for price-related keywords
        keywords = ["Selling", "Buying", "Gold Investment Account", "Daily Price"]
        
        print("\n--- Searching for Keywords ---")
        found = False
        for kw in keywords:
            results = soup.find_all(text=lambda t: t and kw.lower() in t.lower())
            print(f"Keyword '{kw}': {len(results)} matches")
            for res in results[:3]:
                print(f"  Match: {res.strip()}")
                print(f"  Parent: {res.parent}")
                found = True
                
        # Dump table data if any
        print("\n--- Tables Found ---")
        for table in soup.find_all("table"):
            print("Table found:")
            rows = table.find_all("tr")
            for i, row in enumerate(rows):
                cols = [c.get_text(strip=True) for c in row.find_all(['td', 'th'])]
                print(f"  Row {i}: {cols}")
                
        if not found:
            print("\nWARNING: No clear price data found. The page might be loading data dynamically or structure is different.")
            
        with open("cimb_dump.html", "w", encoding="utf-8") as f:
            f.write(soup.prettify())
        print("Saved HTML to cimb_dump.html")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    probe_cimb()
