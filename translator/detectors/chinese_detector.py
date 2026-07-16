import re
from typing import List
from translator.models.segment import Segment
from translator.detectors.detector import LanguageDetector

class ChineseDetector(LanguageDetector):
    """
    Detects Chinese characters in text using Unicode blocks.
    Groups contiguous or closely situated Chinese characters into segments.
    """
    
    def __init__(self):
        # Matches any Chinese character
        # \u4e00-\u9fff is CJK Unified Ideographs
        self.pattern = re.compile(r'[\u4e00-\u9fff]+')

    def find_segments(self, text: str) -> List[Segment]:
        segments = []
        # We can just iterate over all matches
        for match in self.pattern.finditer(text):
            start = match.start()
            end = match.end()
            segment_text = match.group()
            segments.append(Segment(text=segment_text, start=start, end=end))
            
        return segments
