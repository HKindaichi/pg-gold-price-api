
from curl_cffi import requests

def fetch_home():
    url = "https://www.bankislam.com/"
    try:
        r = requests.get(url, impersonate="chrome120", timeout=15)
        print(f"Status: {r.status_code}")
        if r.status_code == 200:
            with open("Scraper/manual/bankislam_home.html", "w", encoding="utf-8") as f:
                f.write(r.text)
            print("Saved to Scraper/manual/bankislam_home.html")
    except Exception as e:
        print(e)

if __name__ == "__main__":
    fetch_home()
