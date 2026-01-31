
import requests

def fetch_js():
    url = "https://www.uob.com.my/assets/iwov-resources/js/rates/fin_gia.js"
    headers = {"User-Agent": "Mozilla/5.0"}
    try:
        r = requests.get(url, headers=headers)
        print(f"Status: {r.status_code}")
        if r.status_code == 200:
            print(r.text)
    except Exception as e:
        print(e)

if __name__ == "__main__":
    fetch_js()
