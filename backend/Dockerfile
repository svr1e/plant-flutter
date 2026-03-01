# Use an official Python runtime as a parent image
FROM python:3.10-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Set work directory
WORKDIR /app

# Install system dependencies
# Note: libgl1-mesa-glx was removed in Debian Trixie; use libgl1 instead
RUN apt-get update && apt-get install -y \
    build-essential \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy project
COPY backend/ .

# Expose port (Render sets $PORT dynamically)
EXPOSE 8000

# Command to run — Render overrides this via startCommand in render.yaml
CMD ["sh", "-c", "gunicorn -k uvicorn.workers.UvicornWorker main:app --workers 1 --timeout 120 --bind 0.0.0.0:$PORT"]
