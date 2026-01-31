
import requests
import json

def probe_uob_api():
    url = "https://www.uob.com.my/online-rates/data/gold-prices.json" # Predicting .json extension or just path
    # Try without extent first
    urls = [
        "https://www.uob.com.my/online-rates/data/gold-prices",
        "https://www.uob.com.my/online-rates/data/gold-prices.json",
        "https://www.uob.com.my/online-rates/data/gold-prices.html"
    ]
    
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36"
    }

    for u in urls:
        print(f"Fetching {u}...")
        try:
            r = requests.get(u, headers=headers, timeout=10)
            print(f"Status: {r.status_code}")
            if r.status_code == 200:
                print(r.text[:500])
                # check if json
                try:
                    print(json.dumps(r.json(), indent=2))
                except:
                    print("Not JSON")
        except Exception as e:
            print(e)
            
if __name__ == "__main__":
    probe_uob_api()
