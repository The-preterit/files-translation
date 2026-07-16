from dataclasses import dataclass

@dataclass
class Segment:
    """
    Represents a portion of text in the target language.
    Contains the original text, and its exact position in the string.
    """
    text: str
    start: int
    end: int
