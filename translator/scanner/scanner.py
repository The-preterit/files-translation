from pathlib import Path
from typing import List
from translator.config import Config

class Scanner:
    """
    Scans a directory for files to process, ignoring configured directories, files, and extensions.
    """
    def __init__(self, config: Config):
        self.config = config

    def scan(self) -> List[Path]:
        """
        Recursively scans the project directory and returns a list of files to process.
        """
        files_to_process = []
        
        if not self.config.project_directory.exists() or not self.config.project_directory.is_dir():
            return files_to_process

        for path in self.config.project_directory.rglob('*'):
            if path.is_file():
                if self._should_ignore(path):
                    continue
                files_to_process.append(path)
                
        return files_to_process

    def _should_ignore(self, path: Path) -> bool:
        """
        Checks if a file path should be ignored based on configuration.
        """
        # Check ignored directories
        for part in path.parts:
            if part in self.config.ignored_directories:
                return True
                
        # Check ignored extensions
        if path.suffix.lower() in [ext.lower() for ext in self.config.ignored_extensions]:
            return True
            
        # Check ignored files
        if path.name in self.config.ignored_files:
            return True
            
        return False
