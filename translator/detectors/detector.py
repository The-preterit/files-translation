from abc import ABC, abstractmethod
from typing import List
from translator.models.segment import Segment

class LanguageDetector(ABC):
    """
    Interface for language detectors.
    """
    
    @abstractmethod
    def find_segments(self, text: str) -> List[Segment]:
        """
        Finds segments of the target language within the text.
        Returns a list of Segment objects.
        """
        pass
