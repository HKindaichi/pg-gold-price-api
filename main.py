from flask import Flask, jsonify
import requests
from bs4 import BeautifulSoup
from datetime import datetime

app = Flask(__name__)

PG_URL = "https://publicgold.com.my/"


def clean_num(s: str) -> int:
    s = s.replace("RM", "").replace(",", "").strip()
    return int(float(s))


def pick_pg_jewel_table(soup: BeautifulSoup):
    """
    Pick the correct table that contains:
    - headers: Purity, PG Sell, PG Buy
    - rows including 999 and 916
    """
    tables = soup.find_all("table")

    for t in tables:
        txt = t.get_text(" ", strip=True).upper()

        has_headers = ("PURITY" in txt) and ("PG SELL" in txt) and ("PG BUY" in txt)
        has_values = ("999" in txt) and ("916" in txt)

        if has_headers and has_values:
            return t

    return None


def get_pg_prices():
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
        target = pick_pg_jewel_table(soup)

        if not target:
            return None

        prices = {}

        # Extract rows
        for row in target.find_all("tr"):
            cols = [c.get_text(strip=True) for c in row.find_all(["td", "th"])]
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
    r = requests.get(
        PG_URL,
        timeout=20,
        headers={"User-Agent": "Mozilla/5.0"}
    )
    soup = BeautifulSoup(r.text, "html.parser")
    tables = soup.find_all("table")

    info = []
    for i, t in enumerate(tables):
        txt = t.get_text(" ", strip=True).upper()
        info.append({
            "index": i,
            "has_headers": ("PURITY" in txt and "PG SELL" in txt and "PG BUY" in txt),
            "has_999_916": ("999" in txt and "916" in txt),
            "preview": t.get_text(" ", strip=True)[:220]
        })

    return jsonify({
        "status": "ok",
        "table_count": len(tables),
        "tables": info
    })


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=10000)
