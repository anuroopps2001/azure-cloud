# 1. Switch to stable Python (3.12) and stable Debian (Bookworm)
FROM python:3.12-slim-bookworm

WORKDIR /app

# 2. Prevent Python from writing pyc files and enable logging
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# 3. Install system dependencies for PostgreSQL and building packages
RUN apt-get update && apt-get install -y \
    libpq-dev \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# 4. Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 5. Copy application code
COPY . .

EXPOSE 8000

# This command assumes you have a file named app.py in your current directory, and within that file, 
# you have an object created like app = FastAPI() (or a similar ASGI app instance)
# --host <str>: Specifies the host IP address to bind to. Use --host 0.0.0.0 to make the application accessible on your local network or from external machines
# --port <int>: Specifies the port to run the server on. The default is 8000.
# CMD [ "uvicorn", "app:app", "--host", "0.0.0.0", "--port", "{PORT}" ]
CMD ["sh", "-c", "uvicorn app:app --host 0.0.0.0 --port ${PORT}"]