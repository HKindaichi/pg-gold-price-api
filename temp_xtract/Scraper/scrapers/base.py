from abc import ABC, abstractmethod

class GoldScraper(ABC):
    @abstractmethod
    def get_name(self) -> str:
        pass

    @abstractmethod
    def scrape(self) -> tuple[dict, str | None]:
        """
        Returns a tuple of (gold_items, last_updated_string).
        Example:
        (
            {
                "999": {"sell": 699, "buy": 636, "spread": 63},
                "916": {"sell": 665, "buy": 578, "spread": 87}
            },
            "26 Jan 2026 09:30:00"
        )
        """
        pass
