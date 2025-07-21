FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy source code
COPY src/ ./src/
COPY config.yml .

# Create logs directory
RUN mkdir -p logs

# Create non-root user
RUN useradd -m -u 1000 bot && chown -R bot:bot /app
USER bot

# Expose port for Prometheus metrics
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8000/metrics')" || exit 1

# Run the bot
CMD ["python", "src/bot.py"] 