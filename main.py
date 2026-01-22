from flask import Flask, jsonify
import requests
from bs4 import BeautifulSoup
from datetime import datetime

app = Flask(__name__)

PG_URL = "https://publicgold.com.my/"


def clean_num(s: str) -> int:
    """
    Convert strings like 'RM 683', '683', '683.00' into int 683
    """
    s = s.replace("RM", "").replace(",", "").strip()
    return int(float(s))


def get_pg_prices():
    """
    Scrape PG JEWEL table from publicgold.com.my and return:
    {
      "999": {"sell": 683, "buy": 621},
      "916": {"sell": 649, "buy": 564}
    }
    """
    try:
        r = requests.get(
            PG_URL,
            timeout=20,
            headers={
                "User-Agent": "Mozilla/5.0",
                "Accept-Language": "en-US,en;q=0.9"
            }
        )

        soup = BeautifulSoup(r.text, "html.parser")

        # Find the PG JEWEL table (not necessarily the first table)
        tables = soup.find_all("table")
        target = None

        # Preferred: table containing these headers and label
        for t in tables:
            txt = t.get_text(" ", strip=True).upper()
            if ("PG JEWEL" in txt) and ("PURITY" in txt) and ("PG SELL" in txt) and ("PG BUY" in txt):
                target = t
                break

        if not target:
            return None

        prices = {}

        for row in target.find_all("tr"):
            cols = [c.get_text(strip=True) for c in row.find_all(["td", "th"])]
            # Expect: Purity | PG Sell | PG Buy
            if len(cols) >= 3:
                purity = cols[0].replace(" ", "")
                sell = cols[1]
                buy = cols[2]

                if purity in ["999", "916"]:
                    try:
                        prices[purity] = {
                            "sell": clean_num(sell),
                            "buy": clean_num(buy),
                        }
                    except Exception:
                        pass

        # Ensure we got both
        if "999" not in prices or "916" not in prices:
            return None

        return prices

    except Exception:
        return None


@app.route("/")
def home():
    return "OK. Use /prices"


@app.route("/prices")
def prices():
    data = get_pg_prices()

    if not data:
        return jsonify({
            "status": "error",
            "message": "Failed to fetch data"
        }), 500

    return jsonify({
        "source": "Public Gold (Reference)",
        "country": "Malaysia",
        "updated_at": datetime.now().strftime("%Y-%m-%d %H:%M"),
        "prices": data
    })


@app.route("/debug")
def debug():
    """
    Debug endpoint to see what tables were found and whether any contain 'PG JEWEL'
    """
    r = requests.get(
        PG_URL,
        timeout=20,
        headers={"User-Agent": "Mozilla/5.0"}
    )
    soup = BeautifulSoup(r.text, "html.parser")
    tables = soup.find_all("table")

    info = []
    for i, t in enumerate(tables):
        txt = t.get_text(" ", strip=True)
        info.append({
            "index": i,
            "has_pg_jewel": "PG JEWEL" in txt.upper(),
            "preview": txt[:220]
        })

    return jsonify({
        "status": "ok",
        "table_count": len(tables),
        "tables": info
    })


if __name__ == "__main__":
    # Render listens on port 10000 by default in our setup
    app.run(host="0.0.0.0", port=10000)
