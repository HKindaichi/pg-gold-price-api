import json
import os
import re
from datetime import datetime
from zoneinfo import ZoneInfo

import requests
from bs4 import BeautifulSoup


# =========================
# Config
# =========================
PUBLIC_GOLD_URL = "https://publicgold.com.my/"
MIGAI_URL = "https://www.maybank2u.com.my/maybank2u/malaysia/en/personal/rates/gold_and_silver.page"
OUTPUT_PATH = os.path.join("output", "latest.json")

TIMEZONE = "Asia/Kuala_Lumpur"


# =========================
# Helpers
# =========================
def now_my() -> datetime:
    return datetime.now(ZoneInfo(TIMEZONE))


def format_updated_label(dt: datetime) -> str:
    now = now_my()
    if dt.date() == now.date():
        return f"Today {dt.strftime('%H:%M')}"
    return dt.strftime("%Y-%m-%d %H:%M")


def safe_float(text: str) -> float:
    """
    Convert '652.06', 'RM 652.06', '652.06 ' -> 652.06
    """
    if text is None:
        raise ValueError("Empty number")
    s = text.strip()
    s = s.replace("RM", "").replace(",", "").strip()
    # keep digits + dot only
    m = re.search(r"(\d+(?:\.\d+)?)", s)
    if not m:
        raise ValueError(f"Cannot parse number from: {text}")
    return float(m.group(1))


def safe_int(text: str) -> int:
    return int(round(safe_float(text)))


def spread_value(sell: float, buy: float) -> float:
    return round(sell - buy, 2)


def http_get(url: str) -> str:
    r = requests.get(
        url,
        timeout=25,
        headers={
            "User-Agent": "Mozilla/5.0",
            "Accept-Language": "en-US,en;q=0.9",
        },
    )
    r.raise_for_status()
    return r.text


# =========================
# Scraper: Public Gold
# =========================
def pick_pg_jewel_table(soup: BeautifulSoup):
    tables = soup.find_all("table")
    for t in tables:
        txt = t.get_text(" ", strip=True).upper()
        has_headers = ("PURITY" in txt) and ("PG SELL" in txt) and ("PG BUY" in txt)
        has_values = ("999" in txt) or ("916" in txt)
        if has_headers and has_values:
            return t
    return None


def scrape_public_gold_items() -> dict:
    """
    Output:
      {
        "999": {"sell": 699, "buy": 636, "spread": 63},
        "916": {"sell": 665, "buy": 578, "spread": 87}
      }
    (depends what exists on site)
    """
    html = http_get(PUBLIC_GOLD_URL)
    soup = BeautifulSoup(html, "html.parser")

    table = pick_pg_jewel_table(soup)
    if not table:
        return {}

    items = {}
    for row in table.find_all("tr"):
        cols = [c.get_text(strip=True) for c in row.find_all(["td", "th"])]
        if len(cols) < 3:
            continue

        purity = cols[0].replace(" ", "")
        if purity not in ["999", "916"]:
            continue

        sell = safe_int(cols[1])
        buy = safe_int(cols[2])

        items[purity] = {
            "sell": sell,
            "buy": buy,
            "spread": int(round(sell - buy)),
        }

    return items


# =========================
# Scraper: MIGA-i (Maybank)
# =========================
def scrape_migai_items() -> dict:
    """
    We use: 'For below 100 grams' row only.
    Output:
      {
        "999": {"sell": 652.06, "buy": 637.94, "spread": 14.12}
      }
    """
    html = http_get(MIGAI_URL)
    soup = BeautifulSoup(html, "html.parser")

    # Find the MIGA-i section by heading text (robust-ish)
    # We'll search any text that matches "Maybank Islamic Gold Account-i (MIGA-i)"
    section_text = soup.find(string=re.compile(r"Maybank Islamic Gold Account-i\s*\(MIGA-i\)", re.I))
    if not section_text:
        return {}

    # Find the nearest table after that heading
    heading_el = section_text.parent
    table = heading_el.find_next("table")
    if not table:
        return {}

    # Look for row that contains "below 100"
    target_row = None
    for tr in table.find_all("tr"):
        row_txt = tr.get_text(" ", strip=True).lower()
        if "below" in row_txt and "100" in row_txt:
            target_row = tr
            break

    if not target_row:
        return {}

    tds = [td.get_text(" ", strip=True) for td in target_row.find_all(["td", "th"])]
    # Expected: [Date/Label, Selling, Buying]
    if len(tds) < 3:
        return {}

    sell = round(safe_float(tds[1]), 2)
    buy = round(safe_float(tds[2]), 2)

    return {
        "999": {
            "sell": sell,
            "buy": buy,
            "spread": spread_value(sell, buy),
        }
    }


# =========================
# Build output JSON
# =========================
def build_payload() -> dict:
    dt = now_my()
    updated_label = format_updated_label(dt)

    merchants = []

    # Public Gold
    pg_items = scrape_public_gold_items()
    if pg_items:
        merchants.append(
            {
                "id": "public_gold",
                "name": "Public Gold",
                "items": pg_items,
            }
        )

    # MIGA-i
    migai_items = scrape_migai_items()
    if migai_items:
        merchants.append(
            {
                "id": "miga_i",
                "name": "MIGA-i",
                "items": migai_items,
            }
        )

    return {
        "updated_label": updated_label,
        "merchants": merchants,
    }


def write_output(payload: dict):
    os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)
    with open(OUTPUT_PATH, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=2)


def main():
    payload = build_payload()

    # If nothing scraped, fail workflow (so you notice)
    if not payload.get("merchants"):
        raise SystemExit("No merchants scraped. Check selectors / site changed.")

    write_output(payload)
    print(f"✅ Wrote {OUTPUT_PATH} with {len(payload['merchants'])} merchants.")


if __name__ == "__main__":
    main()
