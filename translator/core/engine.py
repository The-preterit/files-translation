import time
from pathlib import Path
from typing import List, Dict, Any
from concurrent.futures import ThreadPoolExecutor, as_completed

from translator.config import Config
from translator.scanner.scanner import Scanner
from translator.detectors.detector import LanguageDetector
from translator.detectors.chinese_detector import ChineseDetector
from translator.cache.memory_cache import MemoryCache
from translator.writer.file_writer import FileWriter
from translator.translators.translator import Translator
from translator.translators.deepl_translator import DeepLTranslator
from translator.translators.google_translator import GoogleTranslator
from translator.translators.dummy_translator import DummyTranslator
from translator.utils.logger import logger

class TranslationEngine:
    def __init__(self, config: Config):
        self.config = config
        self.scanner = Scanner(config)
        self.writer = FileWriter(config)
        self.cache = MemoryCache() if config.cache_enabled else None
        
        # Detector based on source language (hardcoded to Chinese for now, can be extended)
        self.detector = ChineseDetector()
        
        # Select translator
        if config.translator.lower() == 'deepl':
            self.translator = DeepLTranslator()
        elif config.translator.lower() == 'google':
            self.translator = GoogleTranslator()
        else:
            self.translator = DummyTranslator()
            
        # Stats
        self.stats = {
            "files_scanned": 0,
            "files_modified": 0,
            "segments_detected": 0,
            "segments_translated": 0,
            "segments_from_cache": 0,
            "characters_sent": 0,
            "total_time": 0.0
        }

    def run(self):
        logger.info(f"Starting translation process for {self.config.project_directory}")
        logger.info(f"Target Language: {self.config.target_language}")
        logger.info(f"Dry Run: {self.config.dry_run}")
        
        start_time = time.time()
        
        files = self.scanner.scan()
        self.stats["files_scanned"] = len(files)
        logger.info(f"Found {len(files)} files to scan.")
        
        # Process files in parallel
        with ThreadPoolExecutor(max_workers=self.config.max_workers) as executor:
            future_to_file = {executor.submit(self.process_file, file_path): file_path for file_path in files}
            
            for future in as_completed(future_to_file):
                file_path = future_to_file[future]
                try:
                    future.result()
                except Exception as exc:
                    logger.error(f"File {file_path} generated an exception: {exc}")
                    
        self.stats["total_time"] = time.time() - start_time
        self.print_summary()

    def process_file(self, file_path: Path):
        content = self.writer.read(file_path)
        if not content:
            return
            
        segments = self.detector.find_segments(content)
        if not segments:
            return
            
        logger.info(f"Analyse du fichier : {file_path}")
        logger.info(f"Segments trouvés : {len(segments)}")
        
        # Process cache and build translation batches
        texts_to_translate = []
        translations = []
        
        for segment in segments:
            if self.cache and self.cache.contains(segment.text):
                translations.append(self.cache.get(segment.text))
                # Note: We must safely update dict in concurrent context, but standard dict 
                # operations in CPython are mostly thread-safe due to GIL. Using a lock for stats is safer.
                self.stats["segments_from_cache"] += 1
            else:
                texts_to_translate.append(segment.text)
                # Placeholder for now, will replace with actual translation below
                translations.append(None) 
                
        # Batch translation
        translated_texts = []
        for i in range(0, len(texts_to_translate), self.config.batch_size):
            batch = texts_to_translate[i:i+self.config.batch_size]
            
            if self.config.dry_run:
                # In dry run, we still want to show what would be done
                batch_translations = self.translator.translate(batch, self.config.source_language, self.config.target_language)
            else:
                batch_translations = self.translator.translate(batch, self.config.source_language, self.config.target_language)
            
            translated_texts.extend(batch_translations)
            
            # Update cache
            if self.cache:
                for src, tr in zip(batch, batch_translations):
                    self.cache.set(src, tr)
                    
            # Update stats
            self.stats["characters_sent"] += sum(len(t) for t in batch)
            self.stats["segments_translated"] += len(batch)
            
        # Re-assemble translations
        final_translations = []
        trans_idx = 0
        for i, t in enumerate(translations):
            if t is None:
                final_translations.append(translated_texts[trans_idx])
                trans_idx += 1
            else:
                final_translations.append(t)
                
        self.stats["segments_detected"] += len(segments)
        logger.info(f"Segments traduits : {len(segments)}")
        
        # Replace and write
        modified = self.writer.replace_and_write(file_path, content, segments, final_translations)
        if modified:
            self.stats["files_modified"] += 1

    def print_summary(self):
        logger.info("\n--- Résumé ---")
        logger.info(f"Fichiers analysés : {self.stats['files_scanned']}")
        logger.info(f"Fichiers modifiés : {self.stats['files_modified']}")
        logger.info(f"Segments détectés : {self.stats['segments_detected']}")
        logger.info(f"Segments traduits : {self.stats['segments_translated']}")
        logger.info(f"Segments issus du cache : {self.stats['segments_from_cache']}")
        logger.info(f"Caractères envoyés : {self.stats['characters_sent']}")
        logger.info(f"Temps total : {self.stats['total_time']:.2f} s")
        logger.info("--------------\n")
