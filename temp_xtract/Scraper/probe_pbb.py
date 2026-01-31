
import requests

def probe_pbb():
    url = "https://www.pbebank.com/en/invest/gold-egold-investment-account/"
    headers = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"}
    try:
        r = requests.get(url, headers=headers, timeout=15)
        print(f"Status: {r.status_code}")
        if r.status_code == 200:
            with open("Scraper/manual/pbb_dump.html", "w", encoding="utf-8") as f:
                f.write(r.text)
            print("Saved to Scraper/manual/pbb_dump.html")
    except Exception as e:
        print(e)
        
if __name__ == "__main__":
    probe_pbb()
