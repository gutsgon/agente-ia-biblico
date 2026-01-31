import psycopg2
import pandas as pd
import matplotlib.pyplot as plt
import os

# Configuração de conexão
conn = psycopg2.connect(
    host=os.getenv("POSTGRES_HOST", "postgres_db"),
    port=os.getenv("POSTGRES_PORT", "5432"),
    database=os.getenv("POSTGRES_DB", "llm_metrics_db"),
    user=os.getenv("POSTGRES_USER", "n8n_user"),
    password=os.getenv("POSTGRES_PASSWORD", "n8n_user"),
)

OUTPUT_DIR = os.getenv("OUTPUT_DIR", "/output")
DPI = int(os.getenv("CHART_DPI", "600"))
os.makedirs(OUTPUT_DIR, exist_ok=True)

def add_labels(ax):
    """Adiciona os valores exatos acima das barras com ajuste de posição"""
    for p in ax.patches:
        height = p.get_height()
        ax.annotate(
            f"{height:.2f}",
            (p.get_x() + p.get_width() / 2.0, height),
            ha="center",
            va="bottom",
            xytext=(0, 5),
            textcoords="offset points",
            fontsize=10,
            fontweight="bold",
        )

def save_figure(base_filename: str, dpi: int = 600):
    """
    Salva a figura atual em PNG e PDF.
    - base_filename: nome sem extensão (ex.: 'latencia_media')
    """
    base_path = os.path.join(OUTPUT_DIR, base_filename)

    # PNG (raster) - aplica DPI diretamente
    plt.savefig(f"{base_path}.png", dpi=dpi, bbox_inches="tight")

    # PDF (vetorial). DPI não "muda" vetor, mas é útil caso algo seja rasterizado.
    plt.savefig(f"{base_path}.pdf", dpi=dpi, bbox_inches="tight")

def save_chart(df, x_col, y_col, base_filename, ylabel):
    if df.empty:
        return

    plt.figure(figsize=(10, 6))
    ax = df.plot(kind="bar", x=x_col, y=y_col, legend=False, rot=45, color="#1f77b4")

    plt.xlabel("Modelo")
    plt.ylabel(ylabel)

    # Aumenta a margem superior para o número não bater na borda
    plt.gca().margins(y=0.15)

    add_labels(plt.gca())
    plt.tight_layout()

    save_figure(base_filename, dpi=DPI)

    plt.clf()
    plt.close()

# ==========================================
# 1. TOKENS POR SEGUNDO (TPS) - CORRIGIDO
# ==========================================
tokens_df = pd.read_sql("""
SELECT
  m.name || ':' || m.parameters AS "Modelo",
  SUM(e.total_tokens) / NULLIF(SUM(e.latency_ms), 0) AS tps
FROM llm_metrics.executions e
JOIN llm_metrics.models m ON m.id = e.model_id
GROUP BY "Modelo";
""", conn)

save_chart(tokens_df, "Modelo", "tps", "tokens_por_segundo", "Tokens por Segundo (TPS)")

# ==========================================
# 2. LATÊNCIA MÉDIA - CORRIGIDO
# ==========================================
lat_df = pd.read_sql("""
SELECT
  m.name || ':' || m.parameters AS "Modelo",
  AVG(e.latency_ms) AS avg_latency_sec
FROM llm_metrics.executions e
JOIN llm_metrics.models m ON m.id = e.model_id
GROUP BY "Modelo";
""", conn)

save_chart(lat_df, "Modelo", "avg_latency_sec", "latencia_media", "Tempo Médio de Resposta (Segundos)")

# ==========================================
# 3. HARDWARE (APENAS DADOS VÁLIDOS)
# ==========================================
hw_df = pd.read_sql("""
SELECT
  m.name || ':' || m.parameters AS "Modelo",
  AVG(r.cpu_percent) AS cpu,
  AVG(r.memory_mb) AS ram,
  AVG(r.disk_read_mb) AS disk_read
FROM llm_metrics.resource_metrics r
JOIN llm_metrics.executions e ON e.id = r.execution_id
JOIN llm_metrics.models m ON m.id = e.model_id
GROUP BY "Modelo";
""", conn)

save_chart(hw_df, "Modelo", "cpu", "hardware_cpu", "Uso Médio de CPU (%)")
save_chart(hw_df, "Modelo", "ram", "hardware_ram", "Uso Médio de RAM (MB)")
save_chart(hw_df, "Modelo", "disk_read", "hardware_disco_leitura", "Leitura de Disco (MB/s)")

# ==========================================
# 4. ACURÁCIA MÉDIA
# ==========================================
accuracy_df = pd.read_sql("""
SELECT
  m.name || ':' || m.parameters AS "Modelo",
  AVG(a.score) AS avg_accuracy
FROM llm_metrics.response_accuracy a
JOIN llm_metrics.responses r ON r.id = a.response_id
JOIN llm_metrics.models m ON m.id = r.model_id
GROUP BY "Modelo"
ORDER BY "Modelo";
""", conn)

if not accuracy_df.empty:
    plt.figure(figsize=(10, 6))
    ax = accuracy_df.plot(kind="bar", x="Modelo", y="avg_accuracy", legend=False, rot=45)
    plt.ylabel("Acurácia (0–1)")
    plt.gca().set_ylim(0, 1.1)
    add_labels(plt.gca())
    plt.tight_layout()

    save_figure("acuracia_media", dpi=DPI)

    plt.clf()
    plt.close()

print("✅ Gráficos atualizados: PNG + PDF (600 DPI), TPS corrigido, Escrita removida e rótulos reposicionados.")
