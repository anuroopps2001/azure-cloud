* Public Internet → Application Gateway (SSL Termination)

* Application Gateway → App Service (Python Runtime)

* App Service → Azure VNet Integration (Private Path)

* VNet → Azure Database (Private Endpoint)


**Using Azure Service Connector to connect Python Application and Azure Database for PostgreSQL flexible servers with Azure**

# Azure FastAPI + PostgreSQL Managed Identity Lifecycle

This document detail the end-to-end flow of a request, from the user's browser to the database and back, using **Azure Managed Identity (Passwordless)**.

---

## 1. Request Ingress (Networking)
* **User Action:** A user visits `https://fastapi-backend-dev.azurewebsites.net/db-test`.
* **Azure Load Balancer:** Azure's global infrastructure intercepts the request. It handles **SSL Termination** (converting HTTPS to HTTP for the internal server) to reduce CPU load on your app.
* **Routing:** The request is routed through Azure's internal virtual network to the specific instance of your **App Service**.

---

## 2. Web Server Layer (Python Hosting)
* **Gunicorn (Process Manager):** The "Manager" process on Linux receives the request. It ensures your app is healthy and manages multiple worker processes.
* **Uvicorn (ASGI Server):** A worker process translates the raw web request into a format Python can understand.
* **FastAPI (Application):** Your code identifies the `/db-test` route and triggers the `db_test_endpoint()` function.



---

## 3. The Security Handshake (Managed Identity)
Your code calls `get_db_connection()`, which initiates the **Identity Handshake**:
1.  **Identity Request:** The app (via `DefaultAzureCredential`) contacts the **Azure Instance Metadata Service** (IMDS) at a non-routable IP (`169.254.169.254`). 
2.  **JWT Generation:** Azure verifies that **System Assigned Identity** is enabled for this app and generates a **JSON Web Token (JWT)**.
3.  **Token Return:** The token is returned to your Python code. This token serves as a "Temporary Password" that expires quickly.

---

## 4. Database Authorization (The "Guest List")
1.  **Connection Attempt:** Python opens a socket to the **PostgreSQL Flexible Server**. It sends the username (`fastapi-backend-dev`) and the **JWT Token**.
2.  **Entra ID Verification:** PostgreSQL sends the token to **Microsoft Entra ID** to ensure it is authentic.
3.  **Role Check:** Once verified, the database checks its internal "Guest List" (the **Roles**).
    * **Principal Check:** It finds the entry we created via:  
        `SELECT * FROM pgaadauth_create_principal('fastapi-backend-dev', false, false);`
    * **Permission Check:** It verifies the rights we granted via:  
        `GRANT ALL PRIVILEGES ON DATABASE postgres TO "fastapi-backend-dev";`



---

## 5. Execution & Response
1.  **SQL Query:** The database executes `SELECT version();`.
2.  **Data Return:** The database sends the version string back to Python.
3.  **JSON Response:** FastAPI returns a JSON object to the user:
    ```json
    {
      "database_status": "Connected",
      "Version": "PostgreSQL 17.7..."
    }
    ```

---

## Summary of Responsibility
| Component | Responsibility | Status |
| :--- | :--- | :--- |
| **Azure Portal** | Enabling the "Passport" (Managed Identity) | **Complete** |
| **Cloud Shell** | Adding user to "Guest List" (`pgaadauth`) | **Complete** |
| **Cloud Shell** | Giving user "Keys" to tables (`GRANT`) | **Complete** |
| **Python Code** | Getting the "Badge" (Token) and connecting | **Complete** |