import os
from fastapi import FastAPI
import psycopg
from azure.identity import DefaultAzureCredential


app = FastAPI()

# These variables will be injected by the Service Connector or App Settings
# DB_HOST = os.environ.get("AZURE_POSTGRESQL_HOST")
# DB_NAME = os.environ.get("AZURE_POSTGRESQL_DBNAME")
# DB_USER = os.environ.get("AZURE_POSTGRESQL_DBUSER")


def get_db_connection():
    # Ensure these 3 match your actual Azure resources
    host = "fastapi-db-anu.postgres.database.azure.com"
    user = "fastapi-backend-dev"  # Must match the role you just confirmed exists
    dbname = "postgres"

    credential = DefaultAzureCredential()
    token = credential.get_token("https://ossrdbms-aad.database.windows.net/.default")

    return psycopg.connect(
        host=host,
        user=user,
        dbname=dbname,
        password=token.token,
        sslmode="require"
    )


@app.get("/")
def read_root():
    return {"Status": "FastAPI is running on AppService"}

@app.get("/db-test")
def test_db():
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("SELECT version();")
        db_version = cur.fetchone()
        cur.close()
        conn.close()
        return {"database_status": "Connected", "Version": db_version[0]}
    except Exception as e:
        return {"database_status": "Failed", "error": str(e)}