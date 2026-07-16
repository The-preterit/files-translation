import os
from typing import List
from google.cloud import translate_v2 as translate
from translator.translators.translator import Translator
from translator.utils.logger import logger

class GoogleTranslator(Translator):
    """
    Translator using Google Cloud Translation API.
    """
    
    def __init__(self):
        # Requires GOOGLE_APPLICATION_CREDENTIALS environment variable
        try:
            self.client = translate.Client()
        except Exception as e:
            logger.warning(f"Failed to initialize Google Translation client: {e}")
            self.client = None

    def translate(self, texts: List[str], source: str, target: str) -> List[str]:
        if not texts:
            return []
            
        if not self.client:
            raise ValueError("Google Translation client missing or improperly configured.")
            
        try:
            # target typically "en" or "en-US"
            # Extract standard language codes
            target_code = target.split('-')[0].lower()
            source_code = source.split('-')[0].lower() if source else None
            
            results = self.client.translate(
                texts,
                target_language=target_code,
                source_language=source_code
            )
            
            return [res['translatedText'] for res in results]
        except Exception as e:
            logger.error(f"Google Translation error: {e}")
            raise
