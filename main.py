from flask import Flask, jsonify
import requests
from bs4 import BeautifulSoup
from datetime import datetime
import re

app = Flask(__name__)

PG_URL = "https://pgjewel.my/"


def _num(s: str) -> int:
    m = re.search(r"(\d+(?:\.\d+)?)", s.replace(",", ""))
    if not m:
        raise ValueError("No number found")
    return int(float(m.group(1)))


def get_pg_prices():
    try:
        r = requests.get(PG_URL, timeout=15, headers={
            "User-Agent": "Mozilla/5.0",
            "Accept-Language": "en-US,en;q=0.9"
        })

        soup = BeautifulSoup(r.text, "html.parser")
        page_text = soup.get_text(" ", strip=True)

        pattern = re.compile(
            r"999.*?RM\s*([\d,]+(?:\.\d+)?)\s*\(Sell\).*?RM\s*([\d,]+(?:\.\d+)?)\s*\(Buy\).*?"
            r"916.*?RM\s*([\d,]+(?:\.\d+)?)\s*\(Sell\).*?RM\s*([\d,]+(?:\.\d+)?)\s*\(Buy\)",
            re.IGNORECASE
        )

        m = pattern.search(page_text)
        if not m:
            return None

        sell_999 = _num(m.group(1))
        buy_999 = _num(m.group(2))
        sell_916 = _num(m.group(3))
        buy_916 = _num(m.group(4))

        return {
            "999": {"sell": sell_999, "buy": buy_999},
            "916": {"sell": sell_916, "buy": buy_916},
        }

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


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=10000)
