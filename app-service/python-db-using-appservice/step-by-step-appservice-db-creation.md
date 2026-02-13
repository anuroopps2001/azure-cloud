# Technical Documentation: FastAPI + PostgreSQL on Azure
**Project:** Passwordless Backend Deployment  
**Stack:** Python 3.12, FastAPI, PostgreSQL (Flexible Server), Azure Managed Identity

---

## 1. Architectural Overview
The application uses a **Passwordless** architecture. Instead of storing a database password in a `.env` file or hardcoding it, the App Service proves its identity to the Database using **Microsoft Entra ID (Active Directory)**.

* **App Service:** Runs the FastAPI code.
* **Managed Identity:** A "Digital ID" assigned to the App Service.
* **PostgreSQL Flexible Server:** The database engine configured to recognize Azure Identities.
* **Service Connector:** The bridge that handles the networking/firewall between the two.

---

## 2. Infrastructure Setup (CLI Commands)

### A. Create the Database (Flexible Server)
```bash
az postgres flexible-server create \
  --resource-group AppServiceRG \
  --name fastapi-db-anuroop \
  --location eastus \
  --tier Burstable \
  --sku-name Standard_B1ms \
  --version 16 \
  --active-directory-auth Enabled
  ```

  ### B. Create the App Service
  ```bash
  az webapp create \
  --resource-group AppServiceRG \
  --plan fastapi-plan \
  --name fastapi-backend-dev \
  --runtime "PYTHON:3.12"
  ```


  ### C. Connect the Services (Service Connector)
  This command automates the "plumbing," enabling Identity and opening firewalls.
  ```bash
  az webapp connection create postgres-flexible \
  --resource-group AppServiceRG --name fastapi-backend-dev \
  --target-resource-group AppServiceRG --server fastapi-db-anuroop \
  --database postgres --system-identity
  ```

## 3. Environment Variables & Connectivity
The AZURE_POSTGRESQL_CONNECTIONSTRING
This is a managed variable injected by Azure.

- Value: host=fastapi-db-anuroop.postgres.database.azure.com port=5432 dbname=postgres user=fastapi-backend-dev sslmode=require

- Note: It contains no password. The app uses a temporary JWT Token as the password.

Manual App Settings
Set these to ensure your Python os.getenv() calls function correctly:
```bash
az webapp config appsettings set --resource-group AppServiceRG --name fastapi-backend-dev --settings \
    DB_HOST="fastapi-db-anuroop.postgres.database.azure.com" \
    DB_USER="fastapi-backend-dev" \
    DB_NAME="postgres"
```

## 4. 4. Deployment & Logs
 ### Zip Deployment
Azure's build engine (Oryx) automatically runs pip install -r requirements.txt upon receiving the zip.
```bash
az webapp deploy \
  --resource-group AppServiceRG \
  --name fastapi-backend-dev \
  --src-path fastapi-project.zip
```

  ### Viewing Live Logs
  ```bash
  az webapp log tail --name fastapi-backend-dev --resource-group AppServiceRG

  ```

  ## 5. Internal Database Authorization (Manual SQL)
  Azure handles the infrastructure, but the PostgreSQL engine requires internal registration. This is a one-time setup performed as a DB Admin.

1. **Connect to DB**: az postgres flexible-server connect -n fastapi-db-anuroop -u <admin>

 2. **Register the Identity**:
 ```bash
 SELECT * FROM pgaadauth_create_principal('fastapi-backend-dev', false, false);
 ```

 3. **Grant Permissions:**
 ```bash
 GRANT ALL PRIVILEGES ON DATABASE postgres TO "fastapi-backend-dev";

 ```
 
# Azure App Service: Scaling Analysis

## 1. Current Scaling Status
Based on the metrics observed:
* **Active instance count (1):** Your application is currently running on a single Virtual Machine (VM). Since traffic is low, Azure is only using the minimum required resources to keep the app online.
* **Maximum scale (3):** This is your defined "ceiling." Even if traffic spikes significantly, Azure will not provision more than 3 instances.
* **Autoscaling Behavior:** Azure Monitor tracks metrics (like CPU or Memory). When a threshold is crossed, it "Scales Out" by adding a 2nd or 3rd instance. When traffic drops, it "Scales In" back to 1 to save costs.

---

## 2. Comparison: App Service vs. Azure Functions
As you shift focus to **Azure Functions**, keep these architectural differences in mind:

| Feature | App Service (Web App) | Azure Functions (Serverless) |
| :--- | :--- | :--- |
| **Scaling Model** | Predictive/Rule-based (1 to 3). | Reactive/Elastic (0 to 200+). |
| **Idle State** | Always 1+ instance running (Cost is constant). | 0 instances running (Cost is $0 when idle). |
| **Startup Speed** | Minutes (to provision a full VM). | Milliseconds to Seconds. |
| **Database Impact** | Consistent connection count (max 3). | Burst connection count (can overwhelm DB). |

---

## 3. Key Considerations for PostgreSQL
When moving from your App Service demo to Azure Functions with **Azure Database for PostgreSQL**:

1.  **Connection Pooling:** Because Functions scale rapidly to hundreds of instances, you must use a connection pooler like **PgBouncer** (available in the PostgreSQL Flexible Server settings) to avoid "Too many connections" errors.
2.  **Short-Lived Connections:** Unlike your Web App, which keeps a connection open for a long time, Functions should open a connection, perform the task, and close it immediately.
3.  **Environment Variables:** Store your PostgreSQL connection string in the Function App's **Configuration > Application Settings** just like you did with the Web App.

---

## 4. Next Technical Goal
* **Objective:** Create an `HttpTrigger` Azure Function.
* **Task:** Write a function that accepts a JSON payload and inserts it into your existing PostgreSQL Flexible Server.
