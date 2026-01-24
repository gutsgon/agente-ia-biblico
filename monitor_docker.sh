#!/usr/bin/env bash
set -euo pipefail

# Força o sistema a usar ponto (.) como separador decimal
export LC_NUMERIC=C

DB_NAME="llm_metrics_db"
DB_USER="n8n_user"
CONTAINER_DB="postgres_db"
CONTAINER_TARGET="ollama_llm"
INTERVAL="1.0"

# Função para converter unidades (GiB, MiB, kB) para MB numérico puro
to_mb() {
    local raw_val=$(echo "$1" | xargs | tr ',' '.')
    local val=$(echo "$raw_val" | grep -oE '^[0-9.]+')
    local unit=$(echo "$raw_val" | grep -oE '[A-Za-z]+' | tr '[:lower:]' '[:upper:]')
    
    if [[ -z "$val" ]]; then echo "0.00"; return; fi
    
    case "$unit" in
        GIB|GB)  awk "BEGIN {printf \"%.2f\", $val * 1024}" ;;
        MIB|MB)  awk "BEGIN {printf \"%.2f\", $val}" ;;
        KIB|KB)  awk "BEGIN {printf \"%.2f\", $val / 1024}" ;;
        B)       awk "BEGIN {printf \"%.6f\", $val / 1048576}" ;;
        *)       echo "$val" ;; 
    esac
}

# Trap para encerrar graciosamente
trap "echo 'Monitor finalizado.'; exit" SIGINT SIGTERM

echo "🔍 Verificando container $CONTAINER_TARGET..."
if ! docker ps | grep -q "$CONTAINER_TARGET"; then
    echo "❌ ERRO: Container $CONTAINER_TARGET não está rodando."
    exit 1
fi

echo "📊 Iniciando monitoramento de hardware (pressione Ctrl+C para parar)..."

while true; do
    # Captura stats e já troca vírgula por ponto para evitar erros no awk/cut
    STATS=$(docker stats --no-stream --format "{{.CPUPerc}}|{{.MemUsage}}|{{.NetIO}}|{{.BlockIO}}" "$CONTAINER_TARGET" | tr ',' '.')
    
    if [[ -n "$STATS" ]]; then
        # Extração dos campos
        CPU=$(echo "$STATS" | cut -d'|' -f1 | tr -d '%' | xargs)
        
        # Memória (Lê apenas a parte antes da barra '/')
        MEM_RAW=$(echo "$STATS" | cut -d'|' -f2 | cut -d'/' -f1)
        MEM_MB=$(to_mb "$MEM_RAW")
        
        # Rede
        NET_RX=$(to_mb "$(echo "$STATS" | cut -d'|' -f3 | cut -d'/' -f1)")
        NET_TX=$(to_mb "$(echo "$STATS" | cut -d'|' -f3 | cut -d'/' -f2)")
        
        # Disco (Block IO)
        BLOCK_R=$(to_mb "$(echo "$STATS" | cut -d'|' -f4 | cut -d'/' -f1)")
        BLOCK_W=$(to_mb "$(echo "$STATS" | cut -d'|' -f4 | cut -d'/' -f2)")
        
        # Data/Hora em UTC
        TS_UTC=$(date -u +"%Y-%m-%d %H:%M:%S")

        # Execução do INSERT (Removido o silenciador para vermos o sucesso)
        docker exec "$CONTAINER_DB" psql -U "$DB_USER" -d "$DB_NAME" -c \
        "INSERT INTO llm_metrics.resource_metrics (timestamp, cpu_percent, memory_mb, net_rx_mb, net_tx_mb, disk_read_mb, disk_write_mb) 
         VALUES ('$TS_UTC', $CPU, $MEM_MB, $NET_RX, $NET_TX, $BLOCK_R, $BLOCK_W);"
    fi
    sleep "$INTERVAL"
done
