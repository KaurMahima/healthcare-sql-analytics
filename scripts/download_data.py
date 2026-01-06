import sys
from pathlib import Path
from kaggle.api.kaggle_api_extended import KaggleApi

DATASET = "prasad22/healthcare-dataset"
RAW_DIR = Path("data/raw")


def main():
    RAW_DIR.mkdir(parents=True, exist_ok=True)
    api = KaggleApi()
    api.authenticate()

    print("Downloading metadata...")
    try:
        api.dataset_metadata(
            DATASET,
            path=RAW_DIR)
    except Exception as e:
        print(f"Error: Failed to download dataset metadata for '{DATASET}'.", file=sys.stderr)
        print(f"Details: {type(e).__name__}: {e}", file=sys.stderr)
        print("Please verify:", file=sys.stderr)
        print("  - The dataset name is correct", file=sys.stderr)
        print("  - You have internet connectivity", file=sys.stderr)
        print("  - You have permission to access this dataset", file=sys.stderr)
        print("  - Your Kaggle API credentials are properly configured", file=sys.stderr)
        sys.exit(1)

    print("Downloading dataset from kaggle...")
    try:
        api.dataset_download_files(
            DATASET,
            path=RAW_DIR,
            unzip=True
        )
    except Exception as e:
        print(f"Error: Failed to download dataset files for '{DATASET}'.", file=sys.stderr)
        print(f"Details: {type(e).__name__}: {e}", file=sys.stderr)
        print("Please verify:", file=sys.stderr)
        print("  - The dataset name is correct", file=sys.stderr)
        print("  - You have internet connectivity", file=sys.stderr)
        print("  - You have permission to access this dataset", file=sys.stderr)
        print("  - You have sufficient disk space", file=sys.stderr)
        sys.exit(1)

    files = list(RAW_DIR.glob("*"))
    print("Downloaded files:")
    for f in files:
        print(f"-", f.name)


if __name__ == "__main__":
    main()
