import threading
from typing import Optional

class MemoryCache:
    """
    Thread-safe memory cache for translations.
    """
    
    def __init__(self):
        self._cache = {}
        self._lock = threading.Lock()

    def get(self, key: str) -> Optional[str]:
        """
        Retrieves a translation from the cache.
        """
        with self._lock:
            return self._cache.get(key)

    def set(self, key: str, value: str):
        """
        Stores a translation in the cache.
        """
        with self._lock:
            self._cache[key] = value

    def contains(self, key: str) -> bool:
        """
        Checks if a key is in the cache.
        """
        with self._lock:
            return key in self._cache
