import os
from fastapi import FastAPI, HTTPException
import psycopg
from azure.identity import DefaultAzureCredential

app = FastAPI()

# Environment variables injected via App Service or Service Connector
DB_HOST = os.getenv("AZURE_POSTGRESQL_HOST")
DB_NAME = os.getenv("AZURE_POSTGRESQL_DBNAME")
DB_USER = os.getenv("AZURE_POSTGRESQL_DBUSER")
DB_PORT = os.getenv("AZURE_POSTGRESQL_PORT", "5432")




def get_db_connection():
    if not all([DB_HOST, DB_NAME, DB_USER]):
        raise Exception("Database environment variables are missing")

    try:
        credential = DefaultAzureCredential()
        token = credential.get_token(
            "https://ossrdbms-aad.database.windows.net/.default"
        )
    except Exception as e:
        raise Exception(f"AAD token fetch failed: {str(e)}")

    return psycopg.connect(
        host=DB_HOST,
        dbname=DB_NAME,
        user=DB_USER,
        password=token.token,
        port=DB_PORT,
        sslmode="require",
        autocommit=True
    )
@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/")
def read_root():
    return {"status": "FastAPI running on Azure App Service"}


@app.get("/db-test")
def test_db():
    try:
        with get_db_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT version();")
                version = cur.fetchone()[0]

        return {
            "database_status": "Connected",
            "postgres_version": version
        }

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Database connection failed: {str(e)}"
        )