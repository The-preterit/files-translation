import argparse
from pathlib import Path
from translator.config import Config
from translator.core.engine import TranslationEngine

def main():
    parser = argparse.ArgumentParser(description="Project Language Translator")
    
    parser.add_argument("--project", type=str, required=True, help="Path to the project directory")
    parser.add_argument("--translator", type=str, default="deepl", choices=["deepl", "google", "dummy"], help="Translation API provider")
    parser.add_argument("--source", type=str, default="ZH", help="Source language code")
    parser.add_argument("--target", type=str, default="EN-US", help="Target language code")
    
    parser.add_argument("--ignore-dir", nargs="*", default=[".git", ".idea", ".gradle", "build", "node_modules", "dist", "bin", "obj"], help="Directories to ignore")
    parser.add_argument("--ignore-ext", nargs="*", default=[".png", ".jpg", ".gif", ".jar", ".zip", ".mp4", ".mp3", ".class", ".so", ".dll"], help="Extensions to ignore")
    parser.add_argument("--ignore-file", nargs="*", default=[], help="Specific files to ignore")
    
    parser.add_argument("--batch-size", type=int, default=100, help="Batch size for translation API")
    parser.add_argument("--max-workers", type=int, default=4, help="Maximum number of worker threads")
    
    parser.add_argument("--backup", action="store_true", help="Enable backup (.bak files)")
    parser.add_argument("--no-cache", action="store_true", help="Disable memory cache")
    parser.add_argument("--dry-run", action="store_true", help="Run without modifying any files")

    args = parser.parse_args()

    config = Config(
        project_directory=Path(args.project),
        ignored_directories=args.ignore_dir,
        ignored_extensions=args.ignore_ext,
        ignored_files=args.ignore_file,
        source_language=args.source,
        target_language=args.target,
        translator=args.translator,
        batch_size=args.batch_size,
        backup_enabled=args.backup,
        cache_enabled=not args.no_cache,
        dry_run=args.dry_run,
        max_workers=args.max_workers
    )

    engine = TranslationEngine(config)
    engine.run()

if __name__ == "__main__":
    main()
