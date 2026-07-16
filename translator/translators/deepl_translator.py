import os
import deepl
from typing import List
from translator.translators.translator import Translator
from translator.utils.logger import logger

class DeepLTranslator(Translator):
    """
    Translator using DeepL API.
    """
    
    def __init__(self):
        auth_key = os.environ.get("DEEPL_AUTH_KEY")
        if not auth_key:
            logger.warning("DEEPL_AUTH_KEY not found in environment variables.")
            self.translator = None
        else:
            self.translator = deepl.Translator(auth_key)

    def translate(self, texts: List[str], source: str, target: str) -> List[str]:
        if not texts:
            return []
            
        if not self.translator:
            raise ValueError("DeepL API key missing.")
            
        # Ensure we don't translate empty strings which might cause errors
        filtered_texts = [t if t.strip() else " " for t in texts]
            
        try:
            # Map languages (DeepL format usually e.g. 'ZH' -> 'EN-US')
            result = self.translator.translate_text(
                filtered_texts, 
                source_lang=source.upper() if source else None, 
                target_lang=target.upper()
            )
            
            # Unpack results
            return [res.text if isinstance(res, deepl.TextResult) else res for res in result]
        except Exception as e:
            logger.error(f"DeepL Translation error: {e}")
            raise
