import json
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Dict, Any, Optional
from zoneinfo import ZoneInfo

import requests
from bs4 import BeautifulSoup

# ========= CONFIG =========
TZ_MY = ZoneInfo("Asia/Kuala_Lumpur")
OUT_DIR = Path("output")
OUT_FILE = OUT_DIR / "latest.json"

USER_AGENT = "Mozilla/5.0 (compatible; GoldPriceBot/1.0; +https://example.com)"
REQ_TIMEOUT = 25

# ========= HELPERS =========
def now_my() -> datetime:
    return datetime.now(TZ_MY)

def fmt_updated_at(dt: datetime) -> str:
    return dt.strftime("%Y-%m-%d %H:%M:%S")

def format_updated_label(dt: datetime) -> str:
    now = now_my()
    if dt.date() == now.date():
        return f"Today {dt.strftime('%H:%M')}"
    return dt.strftime("%Y-%m-%d %H:%M")

def safe_float(x) -> Optional[float]:
    try:
        return float(x)
    except Exception:
        return None

def calc_spread(sell: Optional[float], buy: Optional[float]) -> Dict[str, Any]:
    if sell is None or buy is None:
        return {"spread": None, "spread_pct": None}
    spread = sell - buy
    spread_pct = (spread / sell * 100.0) if sell else None
    # keep 2 decimals for pct, 2 decimals for money (some merchants return decimals)
    return {
        "spread": round(spread, 2),
        "spread_pct": (round(spread_pct, 2) if spread_pct is not None else None),
    }

def write_json_atomic(payload: dict) -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    tmp = OUT_FILE.with_suffix(".json.tmp")
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=2)
    tmp.replace(OUT_FILE)

def http_get(url: str) -> str:
    r = requests.get(
        url,
        timeout=REQ_TIMEOUT,
        headers={"User-Agent": USER_AGENT, "Accept-Language": "en-US,en;q=0.9"},
    )
    r.raise_for_status()
    return r.text

def clean_rm_to_number(s: str) -> Optional[float]:
    # Handles: "RM 1,234.50" / "1,234" / "RM1234"
    try:
        s = s.replace("RM", "").replace(",", "").strip()
        return float(s)
    except Exception:
        return None

# ========= DATA MODEL =========
@dataclass
class MerchantResult:
    id: str
    name: str
    country: str = "Malaysia"
    items: Dict[str, Dict[str, Any]] = None  # e.g. {"999": {...}, "916": {...}}
    status: str = "ok"  # ok / error / partial
    error: Optional[str] = None

# ========= MERCHANT SCRAPERS =========
def scrape_public_gold() -> MerchantResult:
    """
    Scrape Public Gold table (999/916) from https://publicgold.com.my/
    Returns items with per-purity source URL (same URL for both).
    """
    PG_URL = "https://publicgold.com.my/"
    merchant = MerchantResult(id="public_gold", name="Public Gold", items={})

    try:
        html = http_get(PG_URL)
        soup = BeautifulSoup(html, "html.parser")

        # Find table that contains headers + values
        target = None
        for t in soup.find_all("table"):
            txt = t.get_text(" ", strip=True).upper()
            has_headers = ("PURITY" in txt) and ("PG SELL" in txt) and ("PG BUY" in txt)
            has_values = ("999" in txt) and ("916" in txt)
            if has_headers and has_values:
                target = t
                break

        if not target:
            merchant.status = "error"
            merchant.error = "Public Gold table not found"
            return merchant

        found = {}
        for row in target.find_all("tr"):
            cols = [c.get_text(strip=True) for c in row.find_all(["td", "th"])]
            if len(cols) >= 3:
                purity = cols[0].replace(" ", "")
                sell_raw = cols[1]
                buy_raw = cols[2]
                if purity in ("999", "916"):
                    sell = clean_rm_to_number(sell_raw)
                    buy = clean_rm_to_number(buy_raw)
                    found[purity] = {"sell": sell, "buy": buy}

        if not found:
            merchant.status = "error"
            merchant.error = "Public Gold values not found"
            return merchant

        # Build items with spread
        for purity, vb in found.items():
            sell = vb.get("sell")
            buy = vb.get("buy")
            item = {
                "sell": sell,
                "buy": buy,
                "source": PG_URL,
                "status": "ok" if (sell is not None and buy is not None) else "error",
            }
            item.update(calc_spread(sell, buy))
            if item["status"] != "ok":
                item["error"] = "Missing sell/buy"
            merchant.items[purity] = item

        # overall status
        ok_count = sum(1 for v in merchant.items.values() if v.get("status") == "ok")
        if ok_count == len(merchant.items):
            merchant.status = "ok"
        elif ok_count == 0:
            merchant.status = "error"
            merchant.error = "Public Gold failed for all purities"
        else:
            merchant.status = "partial"
            merchant.error = "Some purities missing"
        return merchant

    except Exception as e:
        merchant.status = "error"
        merchant.error = f"Public Gold scrape exception: {type(e).__name__}"
        return merchant

# ---- TEMPLATE for next merchants (copy & edit) ----
def scrape_template_merchant() -> MerchantResult:
    """
    TEMPLATE: Replace with real logic later.
    Shows how 999 and 916 can come from different sources.
    """
    merchant = MerchantResult(id="template", name="Template Merchant", items={})
    try:
        # Example: different sources per purity
        SRC_999 = "https://example.com/price-999"
        SRC_916 = "https://example.com/price-916"

        # TODO: fetch/parse each source to get sell/buy
        sell_999, buy_999 = None, None
        sell_916, buy_916 = None, None

        for purity, (sell, buy, src) in {
            "999": (sell_999, buy_999, SRC_999),
            "916": (sell_916, buy_916, SRC_916),
        }.items():
            item = {
                "sell": sell,
                "buy": buy,
                "source": src,
                "status": "ok" if (sell is not None and buy is not None) else "error",
            }
            item.update(calc_spread(sell, buy))
            if item["status"] != "ok":
                item["error"] = "Not implemented"
            merchant.items[purity] = item

        merchant.status = "partial"
        merchant.error = "Template merchant not implemented"
        return merchant
    except Exception as e:
        merchant.status = "error"
        merchant.error = f"Template exception: {type(e).__name__}"
        return merchant

# ========= MAIN GENERATOR =========
def build_payload(merchants: list[MerchantResult], dt: datetime) -> dict:
    out_merchants = []
    ok_merchants = 0

    for m in merchants:
        md = {
            "id": m.id,
            "name": m.name,
            "country": m.country,
            "status": m.status,
            "items": m.items or {},
        }
        if m.error:
            md["error"] = m.error

        # helpful meta per merchant
        ok_items = sum(1 for v in (m.items or {}).values() if v.get("status") == "ok")
        total_items = len(m.items or {})
        md["meta"] = {"ok_items": ok_items, "total_items": total_items}

        if m.status == "ok":
            ok_merchants += 1

        out_merchants.append(md)

    return {
        "status": "ok" if ok_merchants > 0 else "error",
        "updated_at": fmt_updated_at(dt),
        "updated_label": format_updated_label(dt),
        "timezone": "Asia/Kuala_Lumpur",
        "country": "Malaysia",
        "merchants": out_merchants,
        "meta": {
            "ok_merchants": ok_merchants,
            "total_merchants": len(out_merchants),
            "version": 1,
            "generator": "github-actions",
        },
    }

def main():
    dt = now_my()

    # Add your merchants here (append more scrapers later)
    merchants: list[MerchantResult] = [
        scrape_public_gold(),
        # scrape_template_merchant(),  # enable when you implement it
    ]

    payload = build_payload(merchants, dt)
    write_json_atomic(payload)
    print("✅ Generated output/latest.json")

if __name__ == "__main__":
    main()
