
import requests

def probe_uob_csv():
    url = "https://www.uob.com.my/wsm/stayinformed.do?path=gia"
    headers = {"User-Agent": "Mozilla/5.0"}
    try:
        r = requests.get(url, headers=headers, timeout=15)
        print(f"Status: {r.status_code}")
        print(r.text)
    except Exception as e:
        print(e)

if __name__ == "__main__":
    probe_uob_csv()
