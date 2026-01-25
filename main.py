import json
import os
from datetime import datetime
from zoneinfo import ZoneInfo

import requests
from bs4 import BeautifulSoup

PG_URL = "https://publicgold.com.my/"
OUTPUT_PATH = os.path.join("output", "latest.json")


def now_my() -> datetime:
    return datetime.now(ZoneInfo("Asia/Kuala_Lumpur"))


def format_updated_label(dt: datetime) -> str:
    now = now_my()
    if dt.date() == now.date():
        return f"Today {dt.strftime('%H:%M')}"
    return dt.strftime("%Y-%m-%d %H:%M")


def clean_num(s: str) -> int:
    # Example "RM 699" / "699" / "699.00"
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


def scrape_public_gold():
    """
    Return:
    {
      "id": "public_gold",
      "name": "Public Gold",
      "updated_label": "...",
      "items": {
        "999": {"sell": 699, "buy": 636, "spread": 63},
        "916": {"sell": 665, "buy": 578, "spread": 87}
      }
    }
    """
    r = requests.get(
        PG_URL,
        timeout=25,
        headers={
            "User-Agent": "Mozilla/5.0 (compatible; pg-gold-price-bot/1.0)",
            "Accept-Language": "en-US,en;q=0.9",
        },
    )
    r.raise_for_status()

    soup = BeautifulSoup(r.text, "html.parser")
    table = pick_pg_jewel_table(soup)
    if not table:
        raise RuntimeError("Public Gold table not found (page structure changed).")

    prices = {}
    for row in table.find_all("tr"):
        cols = [c.get_text(strip=True) for c in row.find_all(["td", "th"])]
        if len(cols) >= 3:
            purity = cols[0].replace(" ", "")
            sell = cols[1]
            buy = cols[2]
            if purity in ["999", "916"]:
                sell_n = clean_num(sell)
                buy_n = clean_num(buy)
                prices[purity] = {
                    "sell": sell_n,
                    "buy": buy_n,
                    "spread": abs(sell_n - buy_n),
                }

    # Hard check
    if "999" not in prices or "916" not in prices:
        raise RuntimeError("Public Gold missing 999/916 rows after parsing.")

    return {
        "id": "public_gold",
        "name": "Public Gold",
        "items": prices,
    }


def scrape_miga_i_placeholder():
    """
    Placeholder untuk MIGA-i.
    Nanti bila kau confirm source/logic MIGA-i, kita ganti function ni.

    Buat masa sekarang, kita return kosong supaya UI tak pecah.
    """
    return {
        "id": "miga_i",
        "name": "MIGA-i",
        "items": {}  # nanti isi "999"/"916"
    }


def build_payload():
    ts = now_my()
    updated_label = format_updated_label(ts)

    merchants = []
    # Public Gold
    merchants.append(scrape_public_gold())
    # MIGA-i (placeholder dulu)
    merchants.append(scrape_miga_i_placeholder())

    return {
        "updated_label": updated_label,
        "merchants": merchants,
    }


def ensure_output_dir():
    os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)


def main():
    ensure_output_dir()
    payload = build_payload()

    with open(OUTPUT_PATH, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=2)

    print(f"✅ Wrote {OUTPUT_PATH}")
    print(json.dumps(payload, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
