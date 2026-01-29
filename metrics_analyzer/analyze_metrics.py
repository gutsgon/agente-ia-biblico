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

def add_labels(ax):
    """Adiciona os valores exatos acima das barras com ajuste de posição"""
    for p in ax.patches:
        height = p.get_height()
        ax.annotate(f'{height:.2f}', 
                    (p.get_x() + p.get_width() / 2., height), 
                    ha='center', va='bottom',  # Alinhamento pela base do texto
                    xytext=(0, 5),             # 5 pontos de distância acima da barra
                    textcoords='offset points',
                    fontsize=10,
                    fontweight='bold')

def save_chart(df, x_col, y_col, filename, ylabel):
    if df.empty:
        return
    plt.figure(figsize=(10, 6))
    ax = df.plot(kind="bar", x=x_col, y=y_col, legend=False, rot=45, color='#1f77b4')
    
    # Ajustes de layout e eixos
    plt.xlabel("Modelo")
    plt.ylabel(ylabel)
    
    # Aumenta a margem superior em 15% para o número não bater na linha do gráfico
    plt.gca().margins(y=0.15) 
    
    add_labels(plt.gca())
    plt.tight_layout()
    plt.savefig(f"/output/{filename}")
    plt.clf()
    plt.close()

# ==========================================
# 1. TOKENS POR SEGUNDO (TPS) - CORRIGIDO
# ==========================================
# Removida a divisão por 1000, pois a latência já está em segundos
tokens_df = pd.read_sql("""
SELECT
  m.name || ':' || m.parameters AS "Modelo",
  SUM(e.total_tokens) / NULLIF(SUM(e.latency_ms), 0) AS tps
FROM llm_metrics.executions e
JOIN llm_metrics.models m ON m.id = e.model_id
GROUP BY "Modelo";
""", conn)

save_chart(tokens_df, "Modelo", "tps", "tokens_por_segundo.png", "Tokens por Segundo (TPS)")

# ==========================================
# 2. LATÊNCIA MÉDIA - CORRIGIDO
# ==========================================
# Exibe o valor direto do banco, que já é segundos
lat_df = pd.read_sql("""
SELECT
  m.name || ':' || m.parameters AS "Modelo",
  AVG(e.latency_ms) AS avg_latency_sec
FROM llm_metrics.executions e
JOIN llm_metrics.models m ON m.id = e.model_id
GROUP BY "Modelo";
""", conn)

save_chart(lat_df, "Modelo", "avg_latency_sec", "latencia_media.png", "Tempo Médio (Segundos)")

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

# Gráficos individuais de hardware
save_chart(hw_df, "Modelo", "cpu", "hardware_cpu.png", "Uso Médio de CPU (%)")
save_chart(hw_df, "Modelo", "ram", "hardware_ram.png", "Uso Médio de RAM (MB)")
save_chart(hw_df, "Modelo", "disk_read", "hardware_disco_leitura.png", "Leitura de Disco (MB)")

# O gráfico de Escrita de Disco foi removido por conter apenas zeros.

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
    plt.gca().set_ylim(0, 1.1) # Garante espaço para o rótulo acima da barra 1.0
    add_labels(plt.gca())
    plt.tight_layout()
    plt.savefig("/output/acuracia_media.png")
    plt.clf()
    plt.close()

print("✅ Gráficos atualizados: TPS corrigido, Escrita removida e rótulos reposicionados.")