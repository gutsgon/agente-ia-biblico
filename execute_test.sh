#!/usr/bin/env bash
# Inicia o monitor em segundo plano
./monitor_docker.sh &
MONITOR_PID=$!

# Executa os disparos (vai levar cerca de 20 minutos para as 4 perguntas ou mais para 40)
./run_whatsapp_test.sh

# Mata o monitor e vincula os dados
kill $MONITOR_PID


echo "🔗 Vinculando métricas de hardware às execuções da IA..."

# ATENÇÃO: Mudado para o banco llm_metrics_db e corrigido a referência do alias
docker exec -it postgres_db psql -U n8n_user -d llm_metrics_db -c "
UPDATE llm_metrics.resource_metrics r
SET execution_id = e.id
FROM llm_metrics.executions e
WHERE (r.timestamp - INTERVAL '5 hours') BETWEEN e.started_at AND e.finished_at
  AND r.execution_id IS NULL;"

echo "🚀 Dados vinculados com sucesso no banco llm_metrics_db!"
