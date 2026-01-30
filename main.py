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
OUTPUT_PATH = os.path.join("output", "latest.json")

# manual file for MIGA-i
MIGAI_MANUAL_PATH = os.path.join("manual", "migai.json")

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
    s = str(text).strip()
    s = s.replace("RM", "").replace(",", "").strip()
    m = re.search(r"(\d+(?:\.\d+)?)", s)
    if not m:
        raise ValueError(f"Cannot parse number from: {text}")
    return float(m.group(1))


def safe_int(text: str) -> int:
    return int(round(safe_float(text)))


def spread_value(sell: float, buy: float) -> float:
    return round(float(sell) - float(buy), 2)


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


def read_json_file(path: str) -> dict:
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


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
# Manual: MIGA-i
# =========================
def load_migai_manual_items() -> tuple[dict, str | None]:
    """
    Reads manual/migai.json.

    Expected format:
    {
      "updated_label": "Today 16:40",
      "items": { "999": { "sell": 650.01, "buy": 625.26 } }
    }

    Returns: (items_dict_for_api, manual_updated_label_or_none)
    items_dict_for_api:
    {
      "999": {"sell": 650.01, "buy": 625.26, "spread": 24.75}
    }
    """
    if not os.path.exists(MIGAI_MANUAL_PATH):
        return {}, None

    try:
        data = read_json_file(MIGAI_MANUAL_PATH)
    except Exception:
        return {}, None

    items = (data or {}).get("items") or {}
    if not isinstance(items, dict):
        return {}, None

    item_999 = items.get("999") or {}
    if not isinstance(item_999, dict):
        return {}, None

    try:
        sell = round(safe_float(item_999.get("sell")), 2)
        buy = round(safe_float(item_999.get("buy")), 2)
    except Exception:
        return {}, None

    out_items = {
        "999": {
            "sell": sell,
            "buy": buy,
            "spread": spread_value(sell, buy),
        }
    }

    manual_label = data.get("updated_label")
    if isinstance(manual_label, str) and manual_label.strip():
        manual_label = manual_label.strip()
    else:
        manual_label = None

    return out_items, manual_label


# =========================
# Build output JSON
# =========================
def build_payload() -> dict:
    dt = now_my()
    updated_label = format_updated_label(dt)

    merchants = []

    # Public Gold (auto)
    pg_items = scrape_public_gold_items()
    if pg_items:
        merchants.append(
            {
                "id": "public_gold",
                "name": "Public Gold",
                "items": pg_items,
            }
        )

    # MIGA-i (manual)
    migai_items, migai_label = load_migai_manual_items()
    if migai_items:
        merchants.append(
            {
                "id": "miga_i",
                "name": "MIGA-i",
                "items": migai_items,
            }
        )

        # Optional: if manual label exists, expose a separate field (does NOT break FlutterFlow)
        # You can use this later if you want to show "MIGA-i Updated" separately.
        if migai_label:
            return {
                "updated_label": updated_label,
                "migai_updated_label": migai_label,
                "merchants": merchants,
            }

    return {
        "updated_label": updated_label,
        "merchants": merchants,
    }



def write_output(payload: dict):
    os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)
    
    # 1. Write latest.json (existing behavior)
    with open(OUTPUT_PATH, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=2)

    # 2. Append to history.csv
    csv_path = os.path.join("output", "history.csv")
    file_exists = os.path.isfile(csv_path)
    
    # We'll flatten the data for CSV: timestamp, merchant, item, sell, buy, spread
    # format_updated_label returns "Today HH:MM" or "YYYY-MM-DD HH:MM". 
    # For history, we prefer a standard ISO timestamp or similar.
    timestamp = now_my().strftime("%Y-%m-%d %H:%M:%S")

    with open(csv_path, "a", encoding="utf-8") as f:
        # Write header if new file
        if not file_exists:
            f.write("timestamp,merchant,item,sell,buy,spread\n")
        
        for merchant in payload.get("merchants", []):
            m_name = merchant["id"] # public_gold or miga_i
            items = merchant.get("items", {})
            for item_key, item_data in items.items():
                # item_key is "999" or "916"
                sell = item_data.get("sell", 0)
                buy = item_data.get("buy", 0)
                spread = item_data.get("spread", 0)
                
                f.write(f"{timestamp},{m_name},{item_key},{sell},{buy},{spread}\n")



def main():
    payload = build_payload()

    # if public gold missing, fail (so you notice)
    has_pg = any(m.get("id") == "public_gold" for m in payload.get("merchants", []))
    if not has_pg:
        raise SystemExit("Public Gold missing. Scraper likely changed.")

    write_output(payload)
    print(f"✅ Wrote {OUTPUT_PATH} with {len(payload['merchants'])} merchants.")


if __name__ == "__main__":
    main()
