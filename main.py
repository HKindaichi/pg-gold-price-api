from flask import Flask, jsonify, request
import requests
from bs4 import BeautifulSoup
from datetime import datetime
from zoneinfo import ZoneInfo

app = Flask(__name__)

PG_URL = "https://publicgold.com.my/"

# Optional security token for /refresh (set in Render ENV as REFRESH_TOKEN)
REFRESH_TOKEN = None  # will be loaded on first request


# In-memory cache (free & simple for MVP)
CACHE = {
    "data": None,
    "updated_at": None,
    "source": "Public Gold (Reference)",
    "country": "Malaysia"
}


def now_my():
    return datetime.now(ZoneInfo("Asia/Kuala_Lumpur"))


def clean_num(s: str) -> int:
    s = s.replace("RM", "").replace(",", "").strip()
    return int(float(s))


def pick_pg_jewel_table(soup: BeautifulSoup):
    tables = soup.find_all("table")
    for t in tables:
        txt = t.get_text(" ", strip=True).upper()
        has_headers = ("PURITY" in txt) and ("PG SELL" in txt) and ("PG BUY" in txt)
        has_values = ("999" in txt) and ("916" in txt)
        if has_headers and has_values:
            return t
    return None


def scrape_pg_prices():
    """
    Return dict prices or None:
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
        target = pick_pg_jewel_table(soup)
        if not target:
            return None

        prices = {}
        for row in target.find_all("tr"):
            cols = [c.get_text(strip=True) for c in row.find_all(["td", "th"])]
            if len(cols) >= 3:
                purity = cols[0].replace(" ", "")
                sell = cols[1]
                buy = cols[2]
                if purity in ["999", "916"]:
                    prices[purity] = {
                        "sell": clean_num(sell),
                        "buy": clean_num(buy)
                    }

        if "999" not in prices or "916" not in prices:
            return None

        return prices
    except Exception:
        return None


def ensure_token_loaded():
    global REFRESH_TOKEN
    if REFRESH_TOKEN is None:
        # load lazily so it doesn't crash if env missing
        import os
        REFRESH_TOKEN = os.getenv("REFRESH_TOKEN", "")


def update_cache():
    prices = scrape_pg_prices()
    if not prices:
        return False

    CACHE["data"] = prices
    CACHE["updated_at"] = now_my().strftime("%Y-%m-%d %H:%M:%S")
    return True


@app.route("/")
def home():
    return "OK. Use /prices"


@app.route("/prices")
def prices():
    # If cache empty, try fill once
    if CACHE["data"] is None:
        update_cache()

    if CACHE["data"] is None:
        return jsonify({"status": "error", "message": "No cached data yet"}), 500

    return jsonify({
        "source": CACHE["source"],
        "country": CACHE["country"],
        "updated_at": CACHE["updated_at"],
        "prices": CACHE["data"]
    })


@app.route("/refresh")
def refresh():
    """
    Call this endpoint every 6 hours (Malaysia time) to refresh cache.
    Optional: protect with token ?token=XXXX
    """
    ensure_token_loaded()

    # If token set in ENV, require it
    if REFRESH_TOKEN:
        token = request.args.get("token", "")
        if token != REFRESH_TOKEN:
            return jsonify({"status": "error", "message": "Unauthorized"}), 401

    ok = update_cache()
    if not ok:
        return jsonify({"status": "error", "message": "Refresh failed"}), 500

    return jsonify({
        "status": "ok",
        "updated_at": CACHE["updated_at"],
        "prices": CACHE["data"]
    })


@app.route("/debug")
def debug():
    r = requests.get(PG_URL, timeout=20, headers={"User-Agent": "Mozilla/5.0"})
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
    return jsonify({"status": "ok", "table_count": len(tables), "tables": info})


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=10000)
