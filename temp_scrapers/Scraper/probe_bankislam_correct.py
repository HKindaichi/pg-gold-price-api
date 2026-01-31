
from curl_cffi import requests

def probe_correct_url():
    # Correct URL found in home page source
    url = "https://www.bankislam.com/personal-banking/bank-islam-gold-account-biga-i/"
    
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
    }
    
    try:
        print(f"Probing {url}...")
        r = requests.get(url, impersonate="chrome120", headers=headers, timeout=15)
        print(f"Status: {r.status_code}")
        
        if r.status_code == 200:
            with open("Scraper/manual/bankislam_correct_dump.html", "w", encoding="utf-8") as f:
                f.write(r.text)
            print("Saved to Scraper/manual/bankislam_correct_dump.html")
            print(r.text[:500])
        else:
            print(f"Failed with status {r.status_code}")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    probe_correct_url()
