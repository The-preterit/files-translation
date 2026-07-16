from abc import ABC, abstractmethod
from typing import List

class Translator(ABC):
    """
    Interface for translation APIs.
    """
    
    @abstractmethod
    def translate(self, texts: List[str], source: str, target: str) -> List[str]:
        """
        Translates a list of strings from source language to target language.
        Returns a list of translated strings in the same order.
        """
        pass
