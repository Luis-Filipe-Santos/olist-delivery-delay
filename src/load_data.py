import duckdb
from pathlib import Path

DATA = Path("data")
con = duckdb.connect("olist.duckdb")

for csv in sorted(DATA.glob("*.csv")):
    nome = csv.stem.replace("olist_", "").replace("_dataset", "")
    con.execute(
        f"CREATE OR REPLACE TABLE {nome} AS "
        f"SELECT * FROM read_csv_auto('{csv.as_posix()}')"
    )
    n = con.execute(f"SELECT COUNT(*) FROM {nome}").fetchone()[0]
    print(f"{nome}: {n:,} linhas")

con.close()