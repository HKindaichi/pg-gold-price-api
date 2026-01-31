
from curl_cffi import requests

def probe_rhb():
    url = "https://www.rhbgroup.com/personal/deposits/foreign-exchange-rates/precious-metals-exchange-rates/index.html"
    try:
        r = requests.get(url, impersonate="chrome110", timeout=15)
        print(f"Status: {r.status_code}")
        with open("Scraper/manual/rhb_dump.html", "w", encoding="utf-8") as f:
            f.write(r.text)
        print("Saved to Scraper/manual/rhb_dump.html")
    except Exception as e:
        print(e)

if __name__ == "__main__":
    probe_rhb()
