import azure.functions as func
import logging
import psycopg2
import os
import json
from datetime import datetime
from azure.identity import DefaultAzureCredential
from azure.mgmt.postgresqlflexibleservers import PostgreSQLManagementClient

 
# 1. Initialize the Function App
app = func.FunctionApp(http_auth_level=func.AuthLevel.ANONYMOUS)

# ---------------------------------------------------------
# ENDPOINT 1: Add User (POST)
# ---------------------------------------------------------
@app.route(route="AddUser", methods=["POST"]) # Explicitly set POST
def postgres_insert(req: func.HttpRequest) -> func.HttpResponse:
    logging.info("Processing a request to add user to Postgres")

    try:
        req_body = req.get_json()
        username = req_body.get('username')
        if not username:
            return func.HttpResponse("Missing 'username' in JSON", status_code=400)
    except ValueError:
        return func.HttpResponse("Invalid JSON", status_code=400)
    
    conn_str = os.environ["PostgresConnectionString"]  # To connect to DB using environment variable at RUNTIME

    try:
        with psycopg2.connect(conn_str) as conn:
            with conn.cursor() as cursor:
                # Ensure table exists (DevOps Bootstrap)
                cursor.execute("CREATE TABLE IF NOT EXISTS users (id SERIAL PRIMARY KEY, name TEXT NOT NULL);")
                # Insert User
                cursor.execute("INSERT INTO users (name) VALUES (%s)", (username,))
                conn.commit()
        return func.HttpResponse(f"User {username} successfully added.", status_code=201)
    
    except Exception as e:
        # FIXED: Removed the comma and set syntax
        logging.error(f"Database Error: {str(e)}")
        return func.HttpResponse(f"Error connecting to Database: {str(e)}", status_code=500)

# ---------------------------------------------------------
# ENDPOINT 2: Get Users (GET)
# ---------------------------------------------------------
@app.route(route="GetUsers", methods=["GET"])
def postgres_get(req: func.HttpRequest) -> func.HttpResponse:
    logging.info("Processing GET request for users")
    conn_str = os.environ["PostgresConnectionString"] # Get the DB details via environment variables to connect to DB
    try:
        with psycopg2.connect(conn_str) as conn:
            with conn.cursor() as cursor:
                cursor.execute("CREATE TABLE IF NOT EXISTS users (id SERIAL PRIMARY KEY, name TEXT NOT NULL);")
                cursor.execute("SELECT id, name FROM users")
                rows = cursor.fetchall()
                users = [{"id": r[0], "name": r[1]} for r in rows]
        
        # Explicitly return JSON with a 200 status
        return func.HttpResponse(
            body=json.dumps(users), 
            mimetype="application/json", 
            status_code=200
        )
    except Exception as e:
        logging.error(f"GET Error: {str(e)}")
        return func.HttpResponse(f"Error: {str(e)}", status_code=500)


# ---------------------------------------------------------
# TIMER 1: Friday 6PM Cleanup (Dynamic Schedule)
# ---------------------------------------------------------
@app.timer_trigger(schedule="%CleanupSchedule%", arg_name="myTimer", run_on_startup=True)
def friday_db_cleanup(myTimer: func.TimerRequest) -> None:
    logging.info('Timer Trigger: Checking for idle Dev Databases')
    # List all variables your function needs
    required_vars = ["AZURE_SUBSCRIPTION_ID", "DB_RESOURCE_GROUP", "DB_SERVER_NAME"]
    missing_vars = [missing_var for missing_var in required_vars if not os.environ.get(missing_var)]

    if missing_vars:
        logging.error(f"CRITICAL: Missing these variables: {missing_vars}")
        return

    # Credentials through Managed Identity in Azure
    sub_id = os.environ.get("AZURE_SUBSCRIPTION_ID")
    rg_name = os.environ.get("DB_RESOURCE_GROUP")
    server_name = os.environ.get("DB_SERVER_NAME")

    if not all([sub_id, rg_name, server_name]):
        logging.error("Missing environment variables for cleanup task")
        return
    try:
        credential = DefaultAzureCredential()
        client = PostgreSQLManagementClient(credential=credential, subscription_id=sub_id)

        # In a real DevOps scenario, we would check metrics here.
        # For now, we trigger the STOP command as scheduled.
        logging.info(f"Attempting to stop server: {server_name} in {rg_name}")


        # .begin_stop() is an async operation in Azure
        stop_poller = client.servers.begin_stop(rg_name, server_name)
        logging.info(f"Stop command sent to {server_name}. Status: {stop_poller.status()}")
    except Exception as e:
        logging.error(f"Cleanup Error {str(e)}")
