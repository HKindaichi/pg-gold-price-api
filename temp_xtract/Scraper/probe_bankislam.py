
from curl_cffi import requests

def probe_bankislam_session():
    home_url = "https://www.bankislam.com/"
    target_url = "https://www.bankislam.com/personal-banking/investments/bank-islam-gold-account-biga-i/"
    
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
        "Accept-Language": "en-US,en;q=0.9",
    }

    try:
        session = requests.Session()
        
        print(f"Visiting Home: {home_url}...")
        r_home = session.get(home_url, impersonate="chrome120", headers=headers, timeout=15)
        print(f"Home Status: {r_home.status_code}")
        
        print(f"Visiting Target: {target_url}...")
        r_target = session.get(target_url, impersonate="chrome120", headers=headers, timeout=15)
        print(f"Target Status: {r_target.status_code}")
        
        if r_target.status_code == 200:
            with open("Scraper/manual/bankislam_dump.html", "w", encoding="utf-8") as f:
                f.write(r_target.text)
            print("Saved to Scraper/manual/bankislam_dump.html")
            print(r_target.text[:500])
        else:
            print(f"Failed status: {r_target.status_code}")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    probe_bankislam_session()
