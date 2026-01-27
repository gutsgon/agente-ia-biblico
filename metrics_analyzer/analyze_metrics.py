import psycopg2
import pandas as pd
import matplotlib.pyplot as plt
import os

conn = psycopg2.connect(
    host=os.getenv("POSTGRES_HOST"),
    port=os.getenv("POSTGRES_PORT"),
    database=os.getenv("POSTGRES_DB"),
    user=os.getenv("POSTGRES_USER"),
    password=os.getenv("POSTGRES_PASSWORD"),
)

# =========================
# 1. TOKENS POR MODELO
# =========================
tokens_df = pd.read_sql("""
SELECT
  m.name || ':' || m.parameters AS model,
  SUM(e.total_tokens) AS total_tokens
FROM llm_metrics.executions e
JOIN llm_metrics.models m ON m.id = e.model_id
GROUP BY model;
""", conn)

tokens_df.plot(
    kind="bar",
    x="model",
    y="total_tokens",
    legend=False,
    title="Uso Total de Tokens por Modelo"
)
plt.ylabel("Tokens")
plt.tight_layout()
plt.savefig("/output/tokens_por_modelo.png")
plt.clf()

# =========================
# 2. LATÊNCIA MÉDIA
# =========================
lat_df = pd.read_sql("""
SELECT
  m.name || ':' || m.parameters AS model,
  AVG(e.latency_ms) AS avg_latency
FROM llm_metrics.executions e
JOIN llm_metrics.models m ON m.id = e.model_id
GROUP BY model;
""", conn)

lat_df.plot(
    kind="bar",
    x="model",
    y="avg_latency",
    legend=False,
    title="Tempo Médio de Resposta (ms)"
)
plt.ylabel("ms")
plt.tight_layout()
plt.savefig("/output/latencia_media.png")
plt.clf()

# =========================
# 3. HARDWARE (MÉDIAS)
# =========================
hw_df = pd.read_sql("""
SELECT
  m.name || ':' || m.parameters AS model,
  AVG(r.cpu_percent) AS cpu,
  AVG(r.memory_mb) AS ram,
  AVG(r.disk_read_mb) AS disk_read,
  AVG(r.disk_write_mb) AS disk_write,
  AVG(r.net_rx_mb + r.net_tx_mb) AS network
FROM llm_metrics.resource_metrics r
JOIN llm_metrics.executions e ON e.id = r.execution_id
JOIN llm_metrics.models m ON m.id = e.model_id
GROUP BY model;
""", conn)

hw_df.set_index("model")[["cpu", "ram", "disk_read", "disk_write", "network"]] \
    .plot(kind="bar", title="Uso Médio de Hardware por Modelo")

plt.ylabel("Média")
plt.tight_layout()
plt.savefig("/output/hardware_geral.png")
plt.clf()

# =========================
# 4. HARDWARE – PIZZA (RAM)
# =========================
hw_df.set_index("model")["ram"].plot(
    kind="pie",
    autopct="%1.1f%%",
    title="Distribuição Média de Uso de RAM"
)
plt.ylabel("")
plt.tight_layout()
plt.savefig("/output/hardware_ram_pizza.png")
plt.clf()

print("✅ Gráficos gerados com sucesso.")
