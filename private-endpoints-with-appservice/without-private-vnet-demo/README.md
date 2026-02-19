# Azure App Service + PostgreSQL Flexible Server (Public Access) – Setup Documentation

## 📌 Objective

This setup demonstrates how to deploy a FastAPI application on **Azure App Service** and securely connect it to **Azure Database for PostgreSQL Flexible Server** using **Microsoft Entra ID authentication** (password-less access).
This serves as the **baseline architecture** before introducing Private Endpoints and Private Networking.

---

# 🏗️ Architecture Overview (Current State)

```
Client Browser
      ↓
Azure App Service (FastAPI)
      ↓
Public Network (Azure backbone)
      ↓
Azure PostgreSQL Flexible Server
```

### Key Characteristics

* App Service uses **Managed Identity**
* Database uses **Entra ID authentication**
* No passwords stored in application settings
* Public access enabled temporarily for learning/demo

---

# ⚙️ Components Configured

## 1️⃣ PostgreSQL Flexible Server

### Authentication

* PostgreSQL authentication: Enabled
* Microsoft Entra ID authentication: Enabled
* Entra ID Administrator: Your Azure user

### Networking

* Connectivity method:

  * ✔ Public access + Private endpoint support
* Firewall:

  * ✔ Allow Azure services access

### Database Role Verification

Connected via Cloud Shell:
```bash
TOKEN=$(az account get-access-token \
  --resource-type oss-rdbms \
  --query accessToken -o tsv)
```

```bash
psql "host=private-endpoint-demo-db.postgres.database.azure.com \
      port=5432 \
      dbname=postgres \
      user=Anuroop.S@rsystems.com \
      sslmode=require \
      password=$TOKEN"
```

```sql
SELECT rolname FROM pg_roles;
```

Confirmed Entra ID role exists:

```
<Anuroop.S@<redacted>.com>
```

---

## 2️⃣ Azure App Service (Linux)

### Runtime

* Container-based deployment (FastAPI)
* Uvicorn server
* Port exposed via environment variable

### Managed Identity

Enabled:

```
App Service → Identity → System Assigned → ON
```

Purpose:

```
Allows password-less database authentication using Azure AD tokens.
```

---

# 🧾 Application Environment Variables

Configured in:

```
App Service → Configuration → Application Settings
```

| Variable                | Value                                  |
| ----------------------- | -------------------------------------- |
| WEBSITES_PORT           | 8000                                   |
| AZURE_POSTGRESQL_HOST   | `<appserverName>.postgres.database.azure.com` |
| AZURE_POSTGRESQL_DBNAME | postgres                               |
| AZURE_POSTGRESQL_DBUSER | `<appserverName>`      |
| AZURE_POSTGRESQL_PORT   | 5432                                   |

⚠️ No database password required.

---

# 🧠 Authentication Flow (How Login Works)

Instead of using:

```
username + password
```

The application uses:

```
DefaultAzureCredential()
```

Flow:

```
App Service Managed Identity
        ↓
Azure AD issues access token
        ↓
Token used as PostgreSQL password
        ↓
Database validates identity
```

Benefits:

* No secret storage
* Automatic token rotation
* Enterprise security model

---

# 🧪 FastAPI Application Endpoints

## Root Endpoint

```
GET /
```

Response:

```
FastAPI running on Azure App Service
```

---

## Database Test Endpoint

```
GET /db-test
```

Function:

* Generates AAD token
* Connects to PostgreSQL
* Runs:

```sql
SELECT version();
```

Successful response example:

```json
{
  "database_status": "Connected"
}
```

---

# 🔎 Validation Steps Performed

## Environment variables loaded into Appservice 
```bash
az webapp config appsettings set --resource-group private-endpoints-rg --name private-endpoint-demo-python-app --settings WEBSITES_PORT=8000
```

## ✔ Database Connectivity

Connected from Azure Cloud Shell using AAD token:

```bash
az account get-access-token --resource-type oss-rdbms
```

Then authenticated via:

```
psql host=<server>.postgres.database.azure.com
```

---

## ✔ Role Verification

Executed:

```sql
SELECT rolname FROM pg_roles;
```

Confirmed Entra ID principal exists.

---

## ✔ App Service Configuration

Verified:

* Environment variables present
* Managed identity enabled
* Container running successfully

---

# 🧩 Current Security Model

| Layer                   | Status            |
| ----------------------- | ----------------- |
| App Service Identity    | ✔ Enabled         |
| Database Authentication | ✔ Entra ID        |
| Password Storage        | ❌ Not Used        |
| Private Networking      | ❌ Not Enabled Yet |

---

# 🚧 Why Public Access Is Enabled Now

This phase establishes a **baseline working architecture**.

Purpose:

```
Understand normal connectivity before introducing Private Endpoints.
```

Without this step, troubleshooting becomes difficult because:

```
Networking issues and application issues look identical.
```

---

# 🔜 Next Phase – Private Endpoint Architecture

We will evolve the design into:

```
App Service
      ↓
VNet Integration
      ↓
Private Endpoint (PostgreSQL)
      ↓
Database Private IP
```

### What Will Change

* Public access disabled
* DNS resolves database hostname to private IP
* Traffic stays inside Azure VNet

### What Will NOT Change

* Application code
* Connection string
* Environment variables

---

# 🧠 Key Learning Outcome From This Phase

Understanding that:

```
Private Endpoint changes NETWORK PATH
—not—
application configuration.
```

Same hostname:

```
<server>.postgres.database.azure.com
```

But DNS resolution shifts from:

```
Public IP  →  Private IP
```

---

# ✅ Current State Summary

* FastAPI app deployed on Azure App Service
* PostgreSQL Flexible Server configured with Entra ID authentication
* Password-less authentication working
* Public connectivity validated
* Ready to transition into Private Endpoint implementation

---

# 📎 Next Steps

1. Enable VNet Integration for App Service
2. Create Private Endpoint for PostgreSQL
3. Configure Private DNS Zone
4. Disable Public Network Access
5. Validate `/db-test` without code changes
