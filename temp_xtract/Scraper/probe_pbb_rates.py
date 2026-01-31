
import requests

def probe_pbb_rates():
    url = "https://www.pbebank.com/en/rates-charges/"
    headers = {"User-Agent": "Mozilla/5.0"}
    try:
        r = requests.get(url, headers=headers)
        print(f"Status: {r.status_code}")
        with open("Scraper/manual/pbb_rates_dump.html", "w", encoding="utf-8") as f:
            f.write(r.text)
    except Exception as e:
        print(e)
if __name__ == "__main__":
    probe_pbb_rates()
