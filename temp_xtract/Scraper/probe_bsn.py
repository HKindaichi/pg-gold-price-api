
from curl_cffi import requests

def probe_bsn():
    url = "https://www.bsn.com.my/PersonalBanking/WealthManagement/gold-investment"
    try:
        r = requests.get(url, impersonate="chrome110", timeout=15)
        print(f"Status: {r.status_code}")
        with open("Scraper/manual/bsn_dump.html", "w", encoding="utf-8") as f:
            f.write(r.text)
        print("Saved to Scraper/manual/bsn_dump.html")
    except Exception as e:
        print(e)

if __name__ == "__main__":
    probe_bsn()
