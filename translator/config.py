from dataclasses import dataclass, field
from pathlib import Path
from typing import List

@dataclass
class Config:
    project_directory: Path
    ignored_directories: List[str] = field(default_factory=lambda: [
        ".git", ".idea", ".gradle", "build", "node_modules", "dist", "bin", "obj"
    ])
    ignored_extensions: List[str] = field(default_factory=lambda: [
        ".png", ".jpg", ".gif", ".jar", ".zip", ".mp4", ".mp3", ".class", ".so", ".dll"
    ])
    ignored_files: List[str] = field(default_factory=list)
    source_language: str = "ZH"
    target_language: str = "EN-US"
    translator: str = "deepl"  # e.g., 'deepl', 'google', 'dummy'
    batch_size: int = 100
    backup_enabled: bool = True
    cache_enabled: bool = True
    dry_run: bool = False
    max_workers: int = 4
