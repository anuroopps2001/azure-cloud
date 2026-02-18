from fastapi import FastAPI
import psycopg2

app = FastAPI()

@app.get("/health")
def health_check():