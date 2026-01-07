from pathlib import Path
import duckdb
import logging

logging.basicConfig(level=logging.INFO,
                    format="%(asctime)s | %(levelname)s | %(message)s")
logger = logging.getLogger(__name__)

# Resolve paths relative to the project root, regardless of CWD
ROOT = Path(__file__).resolve().parent.parent
CSV_PATH = ROOT / "data/raw/healthcare_dataset.csv"
DB_PATH = ROOT / "data/processed/healthcare_data.duckdb"


def main():
    logger.info("Starting database creation process.")
    if not CSV_PATH.exists():
        raise FileNotFoundError(f"CSV file not found at {CSV_PATH}")

    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    logger.info(f"Creating DuckDB database at {DB_PATH}")
    conn = duckdb.connect(database=str(DB_PATH), read_only=False)

    conn.execute("DROP TABLE IF EXISTS healthcare_data;")
    conn.execute(
        f"CREATE TABLE healthcare_data AS SELECT * FROM read_csv_auto('{CSV_PATH}')")

    n = conn.execute("SELECT count(*) FROM healthcare_data").fetchone()[0]
    logger.info(f"Loaded rows: {n}")

    conn.close()
    logger.info("Done")


if __name__ == "__main__":
    main()
