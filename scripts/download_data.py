from pathlib import Path
from kaggle.api.kaggle_api_extended import KaggleApi

DATASET = "prasad22/healthcare-dataset"
RAW_DIR = Path("data/raw")


def main():
    RAW_DIR.mkdir(parents=True, exist_ok=True)
    api = KaggleApi()
    api.authenticate()

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
