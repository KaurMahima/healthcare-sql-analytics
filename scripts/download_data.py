import sys
from pathlib import Path
from kaggle.api.kaggle_api_extended import KaggleApi

DATASET = "prasad22/healthcare-dataset"
RAW_DIR = Path("data/raw")


def main():
    RAW_DIR.mkdir(parents=True, exist_ok=True)
    api = KaggleApi()
    
    try:
        api.authenticate()
    except Exception as e:
        print("Error: Failed to authenticate with Kaggle API.", file=sys.stderr)
        print("Please ensure your Kaggle API credentials are properly configured.", file=sys.stderr)
        print("", file=sys.stderr)
        print("To set up your credentials:", file=sys.stderr)
        print("1. Go to https://www.kaggle.com/account", file=sys.stderr)
        print("2. Click 'Create New API Token' to download kaggle.json", file=sys.stderr)
        print("3. Place the file at ~/.kaggle/kaggle.json", file=sys.stderr)
        print("4. Ensure the file has proper permissions: chmod 600 ~/.kaggle/kaggle.json", file=sys.stderr)
        print("", file=sys.stderr)
        print(f"Original error: {e}", file=sys.stderr)
        sys.exit(1)

    print(f"Downloading metadata...")
    api.dataset_metadata(
        DATASET,
        path=RAW_DIR)

    print(f"Downloading dataset from kaggle...")
    api.dataset_download_files(
        DATASET,
        path=RAW_DIR,
        unzip=True
    )

    files = list(RAW_DIR.glob("*"))
    print("Downloaded files:")
    for f in files:
        print(f"-", f.name)


if __name__ == "__main__":
    main()
