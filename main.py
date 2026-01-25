import json
import re
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Dict, Any, Optional
from zoneinfo import ZoneInfo

import requests
from bs4 import BeautifulSoup

# ================== CONFIG ==================
TZ_MY = ZoneInfo("Asia/Kuala_Lumpur")
OUT_DIR = Path("output")
OUT_FILE = OUT_DIR / "latest.json"

USER_AGENT = "Mozilla/5.0 (GoldPriceBot/1.0)"
REQ_TIMEOUT = 25

# ================== HELPERS ==================
def now_my() -> datetime:
    return datetime.now(TZ_MY)

def fmt_updated_at(dt: datetime) -> str:
    return dt.strftime("%Y-%m-%d %H:%M:%S")

def format_updated_label(dt: datetime) -> str:
    now = now_my()
    if dt.date() == now.date():
        return f"Today {dt.strftime('%H:%M')}"
    return dt.strftime("%Y-%m-%d %H:%M")

def calc_spread(sell: Optional[float], buy: Optional[float]) -> Dict[str, Any]:
    if sell is None or buy is None:
        return {"spread": None, "spread_pct": None}
    spread = sell - buy
    spread_pct = (spread / sell * 100.0) if sell else None
    return {
        "spread": round(spread, 2),
        "spread_pct": round(spread_pct, 2) if spread_pct else None,
    }

def write_json(payload: dict):
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    with open(OUT_FILE, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=2)

def http_get(url: str) -> str:
    r = requests.get(
        url,
        timeout=REQ_TIMEOUT,
        headers={"User-Agent": USER_AGENT},
    )
    r.raise_for_status()
    return r.text

def clean_rm(s: str) -> Optional[float]:
    try:
        return float(s.replace("RM", "").replace(",", "").strip())
    except Exception:
        return None

# ================== DATA MODEL ==================
@dataclass
class MerchantResult:
    id: str
    name: str
    items: Dict[str, Dict[str, Any]]
    status: str = "ok"
    error: Optional[str] = None

def make_item(sell, buy, source):
    item = {
        "sell": sell,
        "buy": buy,
        "source": source,
        "status": "ok" if sell and buy else "error",
    }
    item.update(calc_spread(sell, buy))
    return item

# ================== PUBLIC GOLD ==================
def scrape_public_gold() -> MerchantResult:
    url = "https://publicgold.com.my/"
    items = {}

    try:
        soup = BeautifulSoup(http_get(url), "html.parser")
        table = None

        for t in soup.find_all("table"):
            txt = t.get_text(" ", strip=True).upper()
            if "PURITY" in txt and "PG SELL" in txt and "PG BUY" in txt:
                table = t
                break

        if not table:
            raise Exception("Table not found")

        for row in table.find_all("tr"):
            cols = [c.get_text(strip=True) for c in row.find_all(["td", "th"])]
            if len(cols) >= 3 and cols[0] in ("999", "916"):
                items[cols[0]] = make_item(
                    clean_rm(cols[1]),
                    clean_rm(cols[2]),
                    url,
                )

        return MerchantResult(
            id="public_gold",
            name="Public Gold",
            items=items,
            status="ok" if items else "error",
        )

    except Exception as e:
        return MerchantResult(
            id="public_gold",
            name="Public Gold",
            items={
                "999": make_item(None, None, url),
                "916": make_item(None, None, url),
            },
            status="error",
            error=str(e),
        )

# ================== MIGA-i (READY) ==================
def scrape_miga_i() -> MerchantResult:
    # Placeholder – enable bila MIGA bagi URL rasmi
    return MerchantResult(
        id="miga_i",
        name="MIGA-i",
        items={
            "999": make_item(None, None, "pending"),
            "916": make_item(None, None, "pending"),
        },
        status="partial",
        error="MIGA-i source not configured yet",
    )

# ================== MAIN ==================
def main():
    now = now_my()

    merchants = [
        scrape_public_gold(),
        scrape_miga_i(),
    ]

    payload = {
        "status": "ok",
        "updated_at": fmt_updated_at(now),
        "updated_label": format_updated_label(now),
        "timezone": "Asia/Kuala_Lumpur",
        "country": "Malaysia",
        "merchants": [
            {
                "id": m.id,
                "name": m.name,
                "status": m.status,
                "items": m.items,
                **({"error": m.error} if m.error else {}),
            }
            for m in merchants
        ],
    }

    write_json(payload)
    print("✅ latest.json generated")

if __name__ == "__main__":
    main()
