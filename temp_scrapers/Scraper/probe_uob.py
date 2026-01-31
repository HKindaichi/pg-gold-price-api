
import requests

def probe_uob():
    url = "https://www.uob.com.my/online-rates/gold-prices.page"
    headers = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"}
    try:
        r = requests.get(url, headers=headers, timeout=15)
        print(f"Status: {r.status_code}")
        with open("Scraper/manual/uob_dump.html", "w", encoding="utf-8") as f:
            f.write(r.text)
        print("Saved to uob_dump.html")
    except Exception as e:
        print(e)
        
if __name__ == "__main__":
    probe_uob()
