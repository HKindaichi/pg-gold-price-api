from bs4 import BeautifulSoup
from scrapers.base import GoldScraper
from utils.common import http_get, safe_int

PUBLIC_GOLD_URL = "https://publicgold.com.my/"

class PublicGoldScraper(GoldScraper):
    def get_name(self) -> str:
        return "Public Gold"

    def _pick_pg_jewel_table(self, soup: BeautifulSoup):
        tables = soup.find_all("table")
        for t in tables:
            txt = t.get_text(" ", strip=True).upper()
            has_headers = ("PURITY" in txt) and ("PG SELL" in txt) and ("PG BUY" in txt)
            has_values = ("999" in txt) or ("916" in txt)
            if has_headers and has_values:
                return t
        return None

    def scrape(self) -> tuple[dict, str | None]:
        html = http_get(PUBLIC_GOLD_URL)
        soup = BeautifulSoup(html, "html.parser")

        # 1. Scrape items
        table = self._pick_pg_jewel_table(soup)
        if not table:
            return {}, None

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

        # 2. Extract Last Updated Text
        # Look for "Last Updated" in the soup (usually in a header)
        # Format often: "Gold Price (Last updated 28-Jan-2026)"
        last_updated_str = None
        import re
        updated_tag = soup.find(text=re.compile("Last Updated", re.I))
        if updated_tag:
            full_text = updated_tag.parent.get_text(strip=True)
            # Try to grab text inside parens if possible
            m = re.search(r"Last updated\s+(.*)\)", full_text, re.I)
            if m:
                last_updated_str = m.group(1).strip()
            else:
                last_updated_str = full_text

        return items, last_updated_str
