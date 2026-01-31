
from curl_cffi import requests

def probe_gb_gold():
    urls = [
        "https://gbgold.my/",
        "https://gbgold.store/"
    ]
    for url in urls:
        print(f"Probing {url}...")
        try:
            r = requests.get(url, impersonate="chrome110", timeout=15)
            print(f"Status: {r.status_code}")
            filename = f"Scraper/manual/gbgold_{url.split('//')[1].replace('/', '').replace('.', '_')}_dump.html"
            with open(filename, "w", encoding="utf-8") as f:
                f.write(r.text)
            print(f"Saved to {filename}")
        except Exception as e:
            print(f"Error probing {url}: {e}")

if __name__ == "__main__":
    probe_gb_gold()
