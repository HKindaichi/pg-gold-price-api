
import requests
from bs4 import BeautifulSoup
import re

def probe_pg():
    url = "https://publicgold.com.my/"
    headers = {"User-Agent": "Mozilla/5.0"}
    try:
        r = requests.get(url, headers=headers, timeout=10)
        soup = BeautifulSoup(r.text, "html.parser")
        
        for tag in soup.find_all(text=re.compile("Last Updated", re.I)):
            print(f"Full Text: '{tag.parent.get_text(strip=True)}'")
            
    except Exception as e:
        print(e)
        
if __name__ == "__main__":
    probe_pg()
