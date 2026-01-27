FROM python:3.11-slim

WORKDIR /app

# Dependências de sistema (
RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Copia dependências
COPY requirements.txt .

# Instala dependências Python
RUN pip install --no-cache-dir -r requirements.txt

# Copia o código
COPY . .

CMD ["python", "analyze_metrics.py"]
