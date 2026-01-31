import requests
from bs4 import BeautifulSoup

URL = "https://www.maybank2u.com.my/maybank2u/malaysia/en/personal/rates/gold_and_silver.page"

def probe():
    print(f"Fetching {URL}...")
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    }
    try:
        r = requests.get(URL, headers=headers, timeout=15)
        print(f"Status Code: {r.status_code}")
        
        soup = BeautifulSoup(r.text, "html.parser")
        text = soup.get_text()
        
        if "Gold" in text:
            print("Found 'Gold' in text.")
        
        # Try to find table
        tables = soup.find_all("table")
        print(f"Found {len(tables)} tables.")
        
        for i, t in enumerate(tables):
            print(f"--- Table {i} ---")
            print(t.prettify()[:500]) # Print first 500 chars of each table
            
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    probe()
