from typing import List
from translator.translators.translator import Translator

class DummyTranslator(Translator):
    """
    Dummy translator for tests and dry runs that simply prefixes text.
    """
    
    def translate(self, texts: List[str], source: str, target: str) -> List[str]:
        if not texts:
            return []
            
        return [f"[TRANSLATED_{target}] {t}" for t in texts]
