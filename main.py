import json
import os
from datetime import datetime
from pathlib import Path
from zoneinfo import ZoneInfo

import requests
from bs4 import BeautifulSoup

PG_URL = "https://publicgold.com.my/"
TZ_MY = ZoneInfo("Asia/Kuala_Lumpur")

OUT_DIR = Path("output")
OUT_FILE = OUT_DIR / "latest.json"


def now_my() -> datetime:
    return datetime.now(TZ_MY)


def format_updated_label(dt: datetime) -> str:
    now = now_my()
    if dt.date() == now.date():
        return f"Today {dt.strftime('%H:%M')}"
    return dt.strftime("%Y-%m-%d %H:%M")


def clean_num(s: str) -> int:
    # handles "RM 1,234.50" etc
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


def scrape_pg_prices() -> dict | None:
    """
    Return dict:
    {
      "999": {"sell": 683, "buy": 621},
      "916": {"sell": 649, "buy": 564}
    }
    """
    try:
        r = requests.get(
            PG_URL,
            timeout=25,
            headers={
                "User-Agent": "Mozilla/5.0",
                "Accept-Language": "en-US,en;q=0.9",
            },
        )
        r.raise_for_status()
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
                        "buy": clean_num(buy),
                    }

        if "999" not in prices or "916" not in prices:
            return None

        return prices
    except Exception:
        return None


def calc_spread(sell: int, buy: int) -> dict:
    spread = int(sell - buy)
    # spread_pct vs sell (common for "how much gap from sell price")
    spread_pct = round((spread / sell) * 100, 2) if sell else None
    return {"spread": spread, "spread_pct": spread_pct}


def build_payload(prices: dict, dt: datetime) -> dict:
    # Enrich each purity with spread info
    enriched = {}
    for purity, v in prices.items():
        sell = int(v["sell"])
        buy = int(v["buy"])
        enriched[purity] = {
            "sell": sell,
            "buy": buy,
            **calc_spread(sell, buy),
        }

    return {
        "status": "ok",
        "source": "Public Gold (Reference)",
        "country": "Malaysia",
        "updated_at": dt.strftime("%Y-%m-%d %H:%M:%S"),
        "updated_label": format_updated_label(dt),
        "timezone": "Asia/Kuala_Lumpur",
        "prices": enriched,
        "meta": {
            "generator": "github-actions",
            "version": 1,
        },
    }


def write_json(payload: dict):
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    tmp = OUT_FILE.with_suffix(".json.tmp")
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=2)
    tmp.replace(OUT_FILE)


def main():
    dt = now_my()
    prices = scrape_pg_prices()

    if not prices:
        # If you want "fail hard" so workflow shows red, set FAIL_ON_SCRAPE=1
        fail_hard = os.getenv("FAIL_ON_SCRAPE", "0") == "1"

        payload = {
            "status": "error",
            "message": "Scrape failed (table not found / network issue).",
            "source": "Public Gold (Reference)",
            "country": "Malaysia",
            "updated_at": dt.strftime("%Y-%m-%d %H:%M:%S"),
            "updated_label": format_updated_label(dt),
            "timezone": "Asia/Kuala_Lumpur",
        }
        write_json(payload)

        if fail_hard:
            raise SystemExit("Scrape failed (FAIL_ON_SCRAPE=1)")
        print("⚠️ Scrape failed, wrote error JSON instead.")
        return

    payload = build_payload(prices, dt)
    write_json(payload)
    print("✅ output/latest.json generated")


if __name__ == "__main__":
    main()
