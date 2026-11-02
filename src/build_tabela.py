import duckdb
from pathlib import Path

con = duckdb.connect("olist.duckdb")
con.execute(Path("sql/01_tabela_analitica.sql").read_text(encoding="utf-8"))

print(con.sql("""
SELECT COUNT(*)                              AS linhas,
       COUNT(DISTINCT order_id)              AS pedidos_unicos,
       SUM(atrasado::INT)                    AS atrasados,
       ROUND(100.0 * AVG(atrasado::INT), 2)  AS pct_atraso,
       SUM(data_inconsistente::INT)          AS datas_inconsistentes,
       SUM((n_itens IS NULL)::INT)           AS sem_itens
FROM analitica_pedidos
""").df().T)
con.close()