# Project Language Translator

A robust Python tool designed to automatically detect and translate specific language segments (e.g., Chinese) to a target language (e.g., English) within a project's source code, **without altering any non-targeted code, formatting, or file structures.**

## Features

- **Precise Segment Detection**: Accurately targets isolated language blocks (e.g., Unicode Chinese characters) while ignoring code elements (variables, structural strings).
- **Non-Destructive Modifications**: Preserves all whitespace, indentation, index spacing, and structural integrity of your code files.
- **Smart Caching**: Implements a thread-safe memory cache to avoid redundant API requests for identical strings.
- **Batch Processing**: Translates large files quickly by grouping segments into batches before requesting translations, significantly lowering API overhead.
- **Concurrent Scanning**: Uses `ThreadPoolExecutor` to evaluate multiple files in parallel for superior performance.
- **Flexible Exclusions**: Easily ignore `.git`, `node_modules`, `build/` directories, and binary extensions via configuration.
- **Support for Major Translation APIs**: Currently integrated with **DeepL** and **Google Cloud Translation**.
- **Dry-run Mode**: Safely preview what would be translated without modifying any actual files.

## Prerequisites

- Python 3.11+
- API Key for DeepL or Google Cloud (depending on your preferred translator).

## Installation

Clone the repository and install the required dependencies:

```bash
pip install -r requirements.txt
```

## Environment Variables

To use the translation APIs, you must set the appropriate environment variable for authentication.

**For DeepL:**
```bash
export DEEPL_AUTH_KEY="your_deepl_api_key_here"
```

**For Google Cloud Translation:**
```bash
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/your/service-account-file.json"
```

## Usage

Run the translator using the CLI entry point.

### Basic Example

```bash
python -m translator.main \
    --project ./path/to/your/project \
    --translator deepl \
    --source ZH \
    --target EN-US
```

### Advanced Example

```bash
python -m translator.main \
    --project ./path/to/your/project \
    --translator google \
    --source ZH \
    --target EN \
    --ignore-dir .git node_modules build \
    --ignore-ext .png .jpg .class .jar \
    --batch-size 100 \
    --max-workers 8 \
    --backup \
    --dry-run
```

### CLI Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `--project` | Path to the directory containing files to translate | **Required** |
| `--translator` | Translation API to use (`deepl`, `google`, `dummy`) | `deepl` |
| `--source` | Source language code | `ZH` |
| `--target` | Target language code | `EN-US` |
| `--ignore-dir` | Folders to skip | `.git`, `node_modules`, `build`, etc. |
| `--ignore-ext` | File extensions to skip | `.png`, `.jpg`, `.jar`, etc. |
| `--batch-size` | Number of segments batched per API call | `100` |
| `--max-workers` | Number of threads for concurrent processing | `4` |
| `--backup` | Flag to generate `.bak` copies before modifications | Disabled |
| `--dry-run` | Flag to simulate the process without writing files | Disabled |
| `--no-cache` | Disable memory caching for identical string translations| Disabled |

## Testing

The project is fully covered by unit and integration tests using `pytest`.

To run the test suite:
```bash
pytest tests/
```

## Architecture & Extensibility

The tool respects the Open/Closed Principle. 
- You can add new translation services by creating a new class implementing the `Translator` interface in `translator/translators/`.
- You can add new language detectors by extending the `LanguageDetector` interface in `translator/detectors/`.
