
from curl_cffi import requests

def probe_gb_gold_api():
    urls = [
        "https://gbgold.my/json/gold-price",
        "https://gbgold.my/api/v3/price/gwa"
    ]
    for url in urls:
        print(f"Probing {url}...")
        try:
            r = requests.get(url, impersonate="chrome110", timeout=15)
            print(f"Status: {r.status_code}")
            print(r.text[:500]) # Print first 500 chars
        except Exception as e:
            print(f"Error probing {url}: {e}")

if __name__ == "__main__":
    probe_gb_gold_api()
