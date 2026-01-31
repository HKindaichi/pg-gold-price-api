
from curl_cffi import requests

def probe_maa():
    urls = [
        "https://www.maaorodesign.com",
        "https://orodesign.biz"
    ]
    
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    }
    
    for url in urls:
        try:
            print(f"Probing {url}...")
            r = requests.get(url, impersonate="chrome120", headers=headers, timeout=15)
            print(f"Status: {r.status_code}")
            
            if r.status_code == 200:
                filename = f"Scraper/manual/maa_{url.split('//')[1].replace('.', '_')}_dump.html"
                with open(filename, "w", encoding="utf-8") as f:
                    f.write(r.text)
                print(f"Saved to {filename}")
                print(r.text[:500])
        except Exception as e:
            print(f"Error connecting to {url}: {e}")

if __name__ == "__main__":
    probe_maa()
