import shutil
from pathlib import Path
from typing import List
from translator.models.segment import Segment
from translator.config import Config

class FileWriter:
    """
    Handles reading, replacing segments, and writing files.
    """
    
    def __init__(self, config: Config):
        self.config = config

    def read(self, file_path: Path) -> str:
        """
        Reads a file as UTF-8, ignoring minor encoding errors.
        """
        try:
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                return f.read()
        except Exception as e:
            from translator.utils.logger import logger
            logger.error(f"Error reading {file_path}: {e}")
            return ""

    def replace_and_write(self, file_path: Path, original_content: str, segments: List[Segment], translations: List[str]) -> bool:
        """
        Replaces segments with translations and writes back to the file.
        Returns True if the file was modified.
        Modifications are done from the end to the beginning to preserve indices.
        """
        if not segments:
            return False
            
        if len(segments) != len(translations):
            raise ValueError("Number of segments and translations must match")
            
        # If dry run, just return
        if self.config.dry_run:
            return True
            
        new_content = original_content
        
        # Sort segments by start position descending (reverse order)
        # We need to zip them first to keep the translation matched
        combined = sorted(zip(segments, translations), key=lambda x: x[0].start, reverse=True)
        
        for segment, translation in combined:
            # Replace precisely
            new_content = new_content[:segment.start] + translation + new_content[segment.end:]
            
        if new_content == original_content:
            return False
            
        # Create backup if needed
        if self.config.backup_enabled:
            backup_path = file_path.with_suffix(file_path.suffix + '.bak')
            shutil.copy2(file_path, backup_path)
            
        # Write new content
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
            
        return True
