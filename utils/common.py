
import json
import re
from datetime import datetime
from zoneinfo import ZoneInfo
import requests

# =========================
# Config
# =========================
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
