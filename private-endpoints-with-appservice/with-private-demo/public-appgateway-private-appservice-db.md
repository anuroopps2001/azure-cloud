```bash
Internet User
     ↓
App Gateway (public IP)
     ↓
App Gateway backend request
     ↓
App Service Private Endpoint  ← inbound to App Service
     ↓
App container
     ↓
PostgreSQL Flexible Server (VNet injected)
```


# Azure Secure Architecture – Notes (Private Endpoints, App Gateway, DNS & VNet Integration)

## 1. Objective of Today’s Work

Today’s goal was to move from a basic App Service deployment into a **secure, enterprise-style private architecture** using:

* Azure Application Gateway (HTTPS ingress)
* Private Endpoint for App Service
* PostgreSQL Flexible Server with private networking
* Managed Identity authentication
* Private DNS resolution
* Understanding inbound vs outbound networking

The focus was not just deployment, but understanding **traffic flow, identity flow, and DNS behaviour**.

---

# 2. High-Level Architecture Implemented

```
Internet User
      ↓
Public Application Gateway (HTTPS)
      ↓
Private Endpoint (App Service)
      ↓
App Service Container
      ↓
PostgreSQL Flexible Server (Private Access)
```

Key principle followed:

* Public exposure only at **App Gateway**
* All backend services remain private.

---

# 3. App Service Networking Concepts

## 3.1 Private Endpoint (Inbound Traffic)

Private Endpoint creates a **private NIC** inside a subnet.

Used when traffic flows **into** App Service:

Examples:

* Application Gateway → App Service
* Client VM → App Service

Characteristics:

* Public access disabled
* Private DNS resolves App Service hostname to private IP
* Secure internal access

Subnet used:

```
appservice-pe-subnet
```

Important Understanding:

Private Endpoint does NOT control outbound traffic.

---

## 3.2 VNet Integration Subnet (Outbound Traffic)

App Service itself is not inside your VNet.

Instead, Azure injects outbound routing through a subnet.

Used when:

* App Service → PostgreSQL
* App Service → Internet APIs
* App Service → Internal services

Subnet used:

```
appservice-vnetint-subnet
```

Future plan:

* NAT Gateway will attach here to control outbound connectivity.

---

# 4. Application Gateway Configuration

## 4.1 Purpose

Application Gateway acts as:

* Reverse proxy
* TLS termination point
* Centralized ingress controller

Traffic Flow:

```
User → HTTPS Listener → Routing Rule → Backend Pool → App Service PE
```

---

## 4.2 Listener

Defines where traffic enters:

* Frontend IP (Public)
* Port 443
* HTTPS protocol
* TLS certificate (.pfx)

Listener does NOT define backend logic.

---

## 4.3 Backend Pool

Represents destination targets.

Configured with:

```
<appservice>.azurewebsites.net
```

Important:

Use FQDN, NOT IP.

Private DNS automatically resolves FQDN to private endpoint IP.

---

## 4.4 Backend Settings (Critical Concept)

Backend settings define HOW App Gateway talks to backend.

Configured values:

* Protocol: HTTPS
* Port: 443
* Complete TLS validation
* Public CA
* Cookie affinity disabled

### Hostname Override (Most Important Setting)

Why needed:

App Service certificate is issued for:

```
*.azurewebsites.net
```

App Gateway connects via private IP internally.

Without hostname override:

* TLS mismatch occurs
* Backend becomes unhealthy

Correct configuration:

```
Override hostname = Enabled
Hostname = <appservice>.azurewebsites.net
```

---

## 4.5 Health Probe

Custom probe configured:

```
Protocol: HTTPS
Path: /health
```

Purpose:

* Validate backend container health
* Prevent 502 gateway errors

---

# 5. Private DNS Behaviour

## 5.1 What Happens When Private Endpoint Is Created

Azure automatically creates private DNS zones such as:

```
privatelink.azurewebsites.net
privatelink.postgres.database.azure.com
```

These zones:

* Map service FQDN → Private IP
* Override public DNS resolution inside VNet

Example:

```
nslookup <appservice>.azurewebsites.net
→ 10.x.x.x (private IP)
```

Important Insight:

Private Endpoint works primarily through **DNS redirection**, not routing rules.

---

## 5.2 One DNS Zone Per Service Type

Observed behaviour:

* App Service Private Endpoint → AzureWebsites DNS zone
* PostgreSQL Flexible Server → Postgres DNS zone

Key Concept:

Azure typically uses **one private DNS zone per service type**, not per resource.

---

# 6. Managed Identity + PostgreSQL Authentication

## 6.1 Identity Flow

Two identities involved:

1. Entra ID Admin (Human user)
2. App Service Managed Identity (Application user)

Admin role responsibilities:

* Create database role matching App Service identity
* Grant permissions

Example SQL:

```
CREATE ROLE "<appservice-name>" WITH LOGIN;
GRANT CONNECT ON DATABASE postgres TO "<appservice-name>";
```

Important Principle:

Human identity is only used for provisioning.

Application runtime uses Managed Identity token.

---

## 6.2 Why Password Was Not Needed

Connection uses:

```
DefaultAzureCredential()
```

App Service retrieves an Entra token automatically.

Token replaces traditional password authentication.

---

# 7. Inbound vs Outbound Networking Model

## 7.1 Inbound (Private Endpoint)

```
App Gateway → App Service
Client VM → App Service
```

Inbound = traffic entering service privately.

---

## 7.2 Outbound (VNet Integration)

```
App Service → PostgreSQL
App Service → Internet
```

Outbound traffic leaves via VNet Integration subnet.

Private Endpoint does not affect outbound behaviour.

---

# 8. NAT Gateway – Planned Next Step

Current outbound behaviour:

```
App Service → Azure platform SNAT → Internet
```

Issues:

* Dynamic outbound IP
* Limited control

Planned improvement:

```
App Service → VNet Integration Subnet → NAT Gateway → Internet
```

Benefits:

* Static outbound IP
* Enterprise-grade egress control
* Better firewall integration

Important Note:

NAT Gateway attaches to:

```
appservice-vnetint-subnet
```

NOT private endpoint subnet.

---

# 9. Key Learnings & Mental Models

## Private Endpoint vs VNet Integration

```
Private Endpoint = Private Entry Door (Inbound)
VNet Integration = Private Exit Route (Outbound)
```

---

## App Gateway Components

```
Listener = Front Door
Routing Rule = Traffic Decision
Backend Pool = Destination
Backend Settings = Communication Method
Health Probe = Availability Check
```

---

## Enterprise Architecture Principles Observed

* Zero public backend exposure
* TLS termination at gateway
* Identity-based DB access
* DNS-driven private connectivity

---

# 10. Tomorrow’s Plan

1. Implement NAT Gateway on VNet Integration subnet.
2. Observe outbound IP behaviour before/after NAT.
3. Begin designing multi-VNet (hub-spoke) architecture.

---

# 11. Current Architecture Maturity Level

Status achieved today:

```
Intermediate Enterprise-Ready Secure Architecture
```

Features in place:

* Private backend services
* Centralized ingress
* Managed Identity authentication
* Private DNS resolution

Next evolution:

* Controlled outbound (NAT Gateway)
* Multi-VNet hub-spoke networking.
