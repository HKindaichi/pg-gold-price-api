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
    if text is None:
        raise ValueError("Empty number")
    s = text.strip().replace("RM", "").replace(",", "").strip()
    m = re.search(r"(\d+(?:\.\d+)?)", s)
    if not m:
        raise ValueError(f"Cannot parse number from: {text}")
    return float(m.group(1))


def safe_int(text: str) -> int:
    return int(round(safe_float(text)))


def spread_value(sell: float, buy: float) -> float:
    return round(sell - buy, 2)


def http_get(url: str, timeout: int = 25, headers: dict | None = None) -> str:
    r = requests.get(
        url,
        timeout=timeout,
        headers=headers
        or {
            "User-Agent": "Mozilla/5.0",
            "Accept-Language": "en-US,en;q=0.9",
        },
    )
    r.raise_for_status()
    return r.text


def http_get_retry(url: str, tries: int = 3, timeout: int = 25, headers: dict | None = None) -> str:
    last_err = None
    for i in range(tries):
        try:
            return http_get(url, timeout=timeout, headers=headers)
        except Exception as e:
            last_err = e
    raise last_err


def http_get_maybank_best_effort(url: str) -> str:
    """
    Maybank sometimes blocks/timeout on GitHub Actions.
    We do: retry + more browser-like headers.
    """
    headers = {
        "User-Agent": (
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
            "AppleWebKit/537.36 (KHTML, like Gecko) "
            "Chrome/120.0.0.0 Safari/537.36"
        ),
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Accept-Language": "en-US,en;q=0.9",
        "Cache-Control": "no-cache",
        "Pragma": "no-cache",
        "Referer": "https://www.maybank2u.com.my/",
        "Connection": "keep-alive",
    }
    return http_get_retry(url, tries=3, timeout=30, headers=headers)


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
    html = http_get_retry(PUBLIC_GOLD_URL, tries=3, timeout=25)
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
def scrape_migai_items_best_effort() -> dict:
    """
    Best-effort scrape.
    If Maybank blocks/timeouts, return {} WITHOUT crashing the whole workflow.
    """
    try:
        html = http_get_maybank_best_effort(MIGAI_URL)

        # Flatten HTML and regex search for: "For below 100 grams 652.06 637.94"
        html_flat = re.sub(r"<[^>]+>", " ", html)
        html_flat = re.sub(r"\s+", " ", html_flat).strip()

        m = re.search(
            r"For\s*below\s*100\s*grams\s*RM?\s*([0-9]+(?:\.[0-9]+)?)\s*RM?\s*([0-9]+(?:\.[0-9]+)?)",
            html_flat,
            re.IGNORECASE,
        )

        if m:
            sell = round(float(m.group(1)), 2)
            buy = round(float(m.group(2)), 2)
            return {
                "999": {
                    "sell": sell,
                    "buy": buy,
                    "spread": spread_value(sell, buy),
                }
            }

        # Fallback: scan tables for "below 100 grams" row
        soup = BeautifulSoup(html, "html.parser")
        for table in soup.find_all("table"):
            for tr in table.find_all("tr"):
                row_txt = tr.get_text(" ", strip=True).lower()
                if ("below" in row_txt) and ("100" in row_txt) and ("gram" in row_txt):
                    cells = [c.get_text(" ", strip=True) for c in tr.find_all(["td", "th"])]
                    if len(cells) >= 3:
                        sell = round(safe_float(cells[1]), 2)
                        buy = round(safe_float(cells[2]), 2)
                        return {
                            "999": {
                                "sell": sell,
                                "buy": buy,
                                "spread": spread_value(sell, buy),
                            }
                        }

        # Not found
        print("⚠️ MIGA-i: pattern not found in HTML (page changed / different content).")
        return {}

    except Exception as e:
        # Important: don't crash the workflow
        print(f"⚠️ MIGA-i scrape failed (non-fatal): {type(e).__name__}: {e}")
        return {}


# =========================
# Build output JSON
# =========================
def build_payload() -> dict:
    dt = now_my()
    updated_label = format_updated_label(dt)

    merchants = []

    # Public Gold (MUST WORK)
    pg_items = scrape_public_gold_items()
    if pg_items:
        merchants.append(
            {
                "id": "public_gold",
                "name": "Public Gold",
                "items": pg_items,
            }
        )

    # MIGA-i (BEST EFFORT)
    migai_items = scrape_migai_items_best_effort()
    merchants.append(
        {
            "id": "miga_i",
            "name": "MIGA-i",
            "items": migai_items,  # boleh {} kalau fail
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

    # Fail only if Public Gold missing (core data)
    has_pg = any(m.get("id") == "public_gold" and m.get("items") for m in payload.get("merchants", []))
    if not has_pg:
        raise SystemExit("Public Gold scrape failed. Check selectors / site changed.")

    write_output(payload)
    print(f"✅ Wrote {OUTPUT_PATH} with {len(payload['merchants'])} merchants.")
    # Print quick check
    for m in payload["merchants"]:
        if m["id"] == "miga_i":
            print("MIGA-i items:", m["items"])


if __name__ == "__main__":
    main()
