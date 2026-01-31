
import requests
import re
import json

def probe_kab():
    url_products = "https://app.kabgold.my/product"
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
        "X-Requested-With": "XMLHttpRequest"
    }
    
    try:
        # 1. Get Product Page to find IDs
        print(f"Fetching {url_products}...")
        r = requests.get(url_products, headers=headers, timeout=15)
        html = r.text
        
        # Find all data-id="123" patterns
        # <span class="fw-bold pricing" data-id="192">0</span>
        ids = set(re.findall(r'data-id="(\d+)"', html))
        print(f"Found IDs: {ids}")
        
        if not ids:
            print("No IDs found.")
            return

        # 2. Call API
        # IDs need to be sent as ids[123]=0 (mock current price)
        # jQuery ajax data { ids: { 123: 0, 124: 0 } } results in url params ids[123]=0&ids[124]=0
        
        params = {}
        for i in ids:
            params[f"ids[{i}]"] = "0"
            
        url_api = "https://app.kabgold.my/product/update-price"
        print(f"Calling API {url_api} with params...")
        
        r_api = requests.get(url_api, headers=headers, params=params, timeout=15)
        print(f"API Status: {r_api.status_code}")
        
        try:
            data = r_api.json()
            print(json.dumps(data, indent=2))
        except:
            print("Failed to parse JSON")
            print(r_api.text[:500])
            
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    probe_kab()
