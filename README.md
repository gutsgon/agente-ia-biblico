# Agente de IA Bíblico no WhatsApp (TCC)

## 📖 Visão Geral do Projeto

Este projeto tem como objetivo desenvolver um **agente de Inteligência Artificial** capaz de responder perguntas bíblicas diretamente pelo **WhatsApp**, auxiliando usuários em **estudos bíblicos rasos ou aprofundados**.

O agente utiliza técnicas de **RAG (Retrieval-Augmented Generation)** para buscar trechos relevantes da Bíblia e fornecer respostas contextualizadas, mantendo fidelidade ao texto bíblico.

O projeto foi idealizado para fins **acadêmicos (TCC)**, com foco em:
- Arquitetura bem definida
- Reprodutibilidade
- Segurança de dados
- Processos claros de inicialização e recuperação

---

## 🧠 Tecnologias Utilizadas

- **Ollama** – Execução de modelos LLM localmente
  - `gemma3:4b` → geração de respostas (modelo principal) 
  - `llama3.2:3b` → geração de respostas (modelo de fallback)
  - `llama3.1:8b` → geração de respostas (modelo reserva)

- **Ollama** - Execução de modelos de embedding para RAG localmente
  - `bge-m3` → embeddings para RAG (modelo principal)
  - `nomic-embed-text` → embeddings para RAG (modelo reserva)

- **Qdrant** – Banco vetorial
- **PostgreSQL** – Persistência de dados do Evolution API
- **Evolution API** – Integração com WhatsApp
- **Docker / Docker Compose**
- **Linux (Ubuntu Server)**

---

## 🏗️ Arquitetura (Visão Geral)

```
WhatsApp
   ↓
Evolution API
   ↓
Agente IA (RAG)
   ↓
N8N
   ↓
Ollama ── Qdrant
   ↓
PostgreSQL
```

---

## 🚀 Inicialização do Ambiente

### 1️⃣ Subir os containers

```bash
docker compose up -d
```

---

## 🤖 Configuração do Ollama

O Ollama **não vem com modelos por padrão**. Para o projeto é necessário um LLM e um para o embedding e RAG (caso tenha dúvidas sobre os modelos leia novamente acima em **Tecnologias**). Para baixar os modelos execute:

```bash
docker exec -it ollama ollama pull gemma3:4b 
docker exec -it ollama ollama pull llama3.2:3b 
docker exec -it ollama ollama pull llama3.1:8b 
docker exec -it ollama ollama pull nomic-embed-text 
docker exec -it ollama pull bge-m3 
```

Verifique:

```bash
docker exec -it ollama ollama list
```

Para rodar um modelo execute (exemplo):

```bash
docker exec -it ollama ollama run gemma3:4b
docker exec -it ollama ollama run bge-m3
```

## Uso de RAG (Retrieval-Augmented Generation)

Para evitar respostas baseadas exclusivamente em conhecimento pré-treinado do modelo, foi adotada a abordagem RAG (Retrieval-Augmented Generation).

Os textos bíblicos são previamente vetorizados e armazenados no banco vetorial Qdrant. A cada pergunta, apenas trechos semanticamente relevantes são recuperados e fornecidos como contexto ao modelo de linguagem.

Essa abordagem garante:
- Redução de alucinações
- Maior fidelidade textual
- Melhor desempenho computacional
- Rastreabilidade das respostas

---


## 📦 Persistência de Dados

Todos os dados são salvos em:

```text
/home/user/docker-data/
├── postgres/
├── qdrant/
├── ollama/
└── backups/
```

Isso garante **resistência à perda de dados** e facilita backups.

---

## 💾 Backup Automático

O backup é feito via script Bash utilizando `cron`.

### Execução manual:
```bash
/backup/backup.sh
```

### Cron (exemplo):
```bash
0 2 * * * /backup/backup.sh
```

Os backups incluem:
- PostgreSQL
- Qdrant
- Dados do Ollama

---

## ♻️ Restauração de Backup

### PostgreSQL
```bash
docker exec -i postgres psql -U postgres evolution_db < backup.sql
```

### Qdrant
```bash
docker compose down
cp -r backup/qdrant/* /home/paulo/docker-data/qdrant/
docker compose up -d
```

### Ollama
```bash
cp -r backup/ollama/* /home/paulo/docker-data/ollama/
```

---

## 🧪 Objetivo Acadêmico

Este agente visa:
- Democratizar o acesso ao estudo bíblico
- Auxiliar líderes, estudantes e curiosos
- Servir como **prova de conceito** para uso de IA em contextos educacionais e religiosos

---

## ✅ Checklist Anti‑Perda de Dados

- [x] Volumes persistentes fora do Docker
- [x] Backup automático diário
- [x] Documentação de restauração
- [x] Modelos versionados
- [x] Processo de inicialização documentado

---

## 📌 Observações Finais

Este projeto prioriza:
- Clareza de processos
- Reprodutibilidade acadêmica
- Segurança e integridade dos dados

Qualquer reinstalação do sistema **não compromete o projeto**, desde que os backups estejam preservados.

---

✝️ *“Lâmpada para os meus pés é a tua palavra, e luz para o meu caminho.”* – Salmos 119:105
