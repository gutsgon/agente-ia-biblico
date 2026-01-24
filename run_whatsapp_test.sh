#!/usr/bin/env bash
set -euo pipefail

EVO_URL="http://localhost:8080/message/sendText/metrics-tester"
API_KEY="l[[6]f3R136#An9.6trP(J+K}e7v7Ck9"
NUMERO="5579991242163"

PROMPTS=(
    "Quem era o pai de Abrão e em qual cidade eles moravam antes de se mudarem para Harã?"
    "Qual foi o sinal da aliança que Deus colecou nas nuvens após o Dilúvio?"
    "De onde Deus tirou o material para criar a mulher?"
    "Em que planície foi construída a torre de Babel?"
)

TOTAL_REPETICOES=10
TOTAL_GERAL=$(( ${#PROMPTS[@]} * TOTAL_REPETICOES ))
CONTADOR=0

echo "📖 Iniciando teste de carga: 4 prompts x 10 repetições = $TOTAL_GERAL envios."

for run in $(seq 1 $TOTAL_REPETICOES); do
    echo "🔄 Iniciando Rodada de Repetição nº $run"
    
    for i in "${!PROMPTS[@]}"; do
        PERGUNTA="${PROMPTS[$i]}"
        CONTADOR=$((CONTADOR + 1))
        
        echo "➡️ [$CONTADOR/$TOTAL_GERAL] Enviando: ${PERGUNTA:0:40}..."

        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$EVO_URL" \
             -H "apikey: $API_KEY" \
             -H "Content-Type: application/json" \
             -d "{
                   \"number\": \"$NUMERO\",
                   \"text\": \"$PERGUNTA\"
                 }")

        if [ "$HTTP_CODE" -eq 201 ] || [ "$HTTP_CODE" -eq 200 ]; then
            echo "✅ Sucesso (201)"
        else
            echo "❌ Erro $HTTP_CODE na rodada $run. Abortando para evitar dados corrompidos."
            exit 1
        fi

        # Aguarda 5 minutos entre CADA uma das 40 mensagens para o n8n e Ollama respirarem
        if [ $CONTADOR -lt $TOTAL_GERAL ]; then
            echo "💤 Aguardando 5 minutos (300s) para estabilização..."
            sleep 300
        fi
    done
done

echo "🏁 Bateria de 40 disparos concluída!"
