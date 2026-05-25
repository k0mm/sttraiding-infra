FROM python:3.12-slim

WORKDIR /app

# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY config/requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY config/ ./

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --retries=3 --start-period=15s \
  CMD curl -sf http://localhost:8080/health || exit 1

CMD ["python", "main.py"]
