# Azure Private Endpoint Learning – Detailed Notes (App Service + PostgreSQL Flexible Server)

---

# 📌 Objective

This document captures the **step-by-step learning journey** of implementing Private Endpoint architecture using:

* Azure App Service
* Azure Database for PostgreSQL Flexible Server
* Virtual Network + Subnets
* Private DNS Zones
* Entra ID authentication

The goal was to understand:

```
How private networking changes connectivity behaviour
without modifying application code.
```

---

# 🧭 Phase 1 – Initial Architecture Understanding

## 🔹 Starting Point

The platform design began with these ideas:

```
App Service
    ↓
PostgreSQL Flexible Server
```

Early confusion focused on:

* Public vs Private access
* DNS resolution behaviour
* Managed Identity authentication
* Why laptop connectivity stopped working

---

# 🧱 Phase 2 – Network Foundation

## ✔ Resource Group

Created a dedicated resource group to isolate the demo environment.

## ✔ Virtual Network

A VNet was designed first to support private connectivity.

Multiple subnets were created:

| Subnet           | Purpose                      |
| ---------------- | ---------------------------- |
| itls subnet      | App Service VNet integration |
| postgres subnet  | PostgreSQL private endpoint  |
| client vm subnet | Internal testing             |

### Key Learning

Private Endpoint requires VNet planning before service creation.

---

# 🗄️ Phase 3 – PostgreSQL Flexible Server Deployment

## 🔐 Authentication Setup

Enabled:

```
✔ PostgreSQL Authentication
✔ Microsoft Entra ID Authentication
```

Configured:

```
Administrator login: psqladmin
Entra ID Administrator: User identity
```

---

## 🌐 Networking Choice (Major Learning Moment)

During server creation:

```
VNet + Subnet selected
```

Azure automatically enforced:

```
PRIVATE ACCESS ONLY
```

Public access option became unavailable.

### Result

```
Laptop → PostgreSQL = BLOCKED
```

Error observed:

```
psql: could not translate host name ... Name or service not known
```

### Root Cause

Private DNS zone only resolves inside VNet.

---

# 🧠 DNS Behaviour Discovery

Running:

```
nslookup db-private-demo.postgres.database.azure.com
```

returned:

```
NXDOMAIN
```

This created confusion initially.

### Explanation Learned

Private Endpoint creates:

```
privatelink.postgres.database.azure.com
```

DNS chain:

```
db-private-demo.postgres.database.azure.com
      ↓ CNAME
db-private-demo.private.postgres.database.azure.com
      ↓
Private DNS Zone
```

Only VNet resources resolve it.

Cloud Shell and Laptop cannot.

---

# 🧩 Phase 4 – App Service Deployment

## ✔ FastAPI application deployed

Application used:

```
DefaultAzureCredential()
```

Authentication flow:

```
App Service Managed Identity
        ↓
Azure AD Token
        ↓
PostgreSQL Login
```

No password stored.

---

## ✔ Environment Variables Configured

```
WEBSITES_PORT = 8000
AZURE_POSTGRESQL_HOST
AZURE_POSTGRESQL_DBNAME
AZURE_POSTGRESQL_DBUSER
AZURE_POSTGRESQL_PORT
```

---

# 🔄 Major Concept Clarification – VNet Integration

A major confusion occurred:

> App Service is integrated with VNet, so shouldn’t it be private?

### Key Learning

```
VNet Integration = Outbound traffic only
```

It allows:

```
App Service → Private DB
```

It does NOT make App Service private for inbound users.

---

# 🌐 Current Traffic Flow

```
External Users → App Service (Public)
App Service → PostgreSQL (Private Endpoint)
```

This is called:

```
Public App Tier + Private Data Tier
```

Common enterprise pattern.

---

# 🧪 Phase 5 – Testing via Client VM

A new subnet was created for client VMs.

Client VM allowed testing inside VNet.

Actions performed:

```
Added Entra ID role inside PostgreSQL
Accessed App Service URL from VM
```

Result:

```
Application worked successfully
```

Meaning:

```
Private DNS
Private Endpoint
Identity Mapping
```

were functioning correctly.

---

# 🧠 Private DNS Zone Understanding

Initial assumption:

```
Each Private Endpoint creates its own DNS zone.
```

Correction learned:

```
DNS zone is created per SERVICE TYPE, not per resource.
```

Examples:

| Service     | DNS Zone                                |
| ----------- | --------------------------------------- |
| PostgreSQL  | privatelink.postgres.database.azure.com |
| App Service | privatelink.azurewebsites.net           |

Multiple resources share same zone.

---

# 🔎 Difference Between Two Private Networking Features

## 1️⃣ VNet Integration

Purpose:

```
Outbound connectivity from App Service.
```

Does NOT make App Service private.

---

## 2️⃣ Private Endpoint (Inbound)

Purpose:

```
Expose service privately inside VNet.
```

Creates:

```
Private IP
Private DNS entry
```

---

# ❓ Doubts Addressed During Learning

## ✔ Why laptop cannot access DB?

Because:

```
Private Endpoint removes public DNS resolution.
```

---

## ✔ Why nslookup shows NXDOMAIN?

Because:

```
Cloud Shell and laptop are outside Private DNS scope.
```

---

## ✔ Do we need to change connection string after Private Endpoint?

```
NO.
```

Hostname stays same.

DNS decides whether to return public or private IP.

---

## ✔ Will Azure always create Private DNS Zone automatically?

Only if:

```
Private DNS integration selected during creation.
```

Otherwise manual setup required.

---

## ✔ Is App Service private now?

```
NO.
```

It remains public unless Private Endpoint is added to App Service itself.

---

# 🏗️ Final Architecture State (After Today)

```
Client VM (VNet)
       ↓
App Service (Public Frontend + VNet Integration)
       ↓
Private Endpoint
       ↓
PostgreSQL Flexible Server
```

Security outcome:

```
✔ Database is private
✔ Public internet cannot reach DB
✔ Internal VNet resources can access app and DB
```

---

# 🎯 Key Takeaways

1. Private Endpoint is primarily a **DNS-driven feature**, not just networking.
2. VNet Integration ≠ Private App Service.
3. Public hostname remains unchanged; DNS determines routing.
4. Private DNS Zones are service-level, not resource-level.
5. Always validate baseline connectivity before moving to private networking.

---

# 🔜 Next Direction (Future Learning)

Potential next steps:

* App Service Private Endpoint (Full Private App)
* Private DNS deep dive
* Internal-only application architecture
* Combining App Gateway with Private Endpoints

---

# ✅ Summary

Over the last two days:

* Built private-first networking architecture
* Understood Private DNS resolution
* Validated secure access using Entra ID authentication
* Observed how Private Endpoint blocks public access but enables VNet communication

This marks a transition from:

```
Public connectivity mindset
```

to:

```
Private Link architecture mindset.
```

---
