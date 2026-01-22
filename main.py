from flask import Flask, jsonify
import requests
from bs4 import BeautifulSoup
from datetime import datetime

app = Flask(__name__)

PG_URL = "https://publicgold.com.my/"

def get_pg_prices():
    try:
        r = requests.get(PG_URL, timeout=10)
        soup = BeautifulSoup(r.text, "html.parser")

        table = soup.find("table")
        rows = table.find_all("tr")

        prices = {}

        for row in rows:
            cols = [c.get_text(strip=True) for c in row.find_all("td")]
            if len(cols) >= 3:
                purity = cols[0]
                sell = cols[1]
                buy = cols[2]

                if purity in ["999", "916"]:
                    prices[purity] = {
                        "sell": int(sell.replace(",", "")),
                        "buy": int(buy.replace(",", ""))
                    }

        return prices

    except Exception:
        return None


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
