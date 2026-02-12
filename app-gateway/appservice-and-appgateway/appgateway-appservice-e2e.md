# Azure Application Gateway → App Service (Container)

## **Production-Grade Traffic Flow — Laptop to Go Container**

This document explains the **real request journey** from a user’s laptop all the way into a container running inside Azure App Service, with TLS termination at Application Gateway.

The goal is to understand:

* Where encryption happens
* Where headers are added
* How ports change
* How Azure internally routes traffic

---

# 1. High-Level Architecture

```
[Laptop / Browser]
        |
        | HTTPS (443)
        v
[Azure Application Gateway]
        |
        | HTTP (80) + Host Rewrite
        v
[Azure App Service Front-End]
        |
        | Internal Routing
        v
[Worker Node]
        |
        | Port Bridge (80 → 8080)
        v
[Docker Container]
        |
        v
[Go Application]
```

---

# 2. Step-by-Step Real Traffic Flow

---

## Step 1 — Request Leaves Your Laptop

User enters:

```
https://<AppGateway-Public-IP>
```

Browser actions:

* Resolves IP
* Starts TLS handshake
* Sends HTTPS request

Example:

```
GET / HTTP/1.1
Host: yourdomain.com
```

Traffic:

```
Laptop → Internet → Azure Public Edge → App Gateway
```

---

## Step 2 — TLS Termination at Application Gateway

Application Gateway Listener receives:

```
Port: 443
Protocol: HTTPS
Certificate: Uploaded .pfx
```

Gateway performs:

* TLS handshake
* Decryption of request

After this point:

```
Traffic becomes plain HTTP internally.
```

Important:

The backend (App Service) never sees encrypted traffic in this architecture.

---

## Step 3 — Routing Rule Decision

Gateway evaluates routing rule:

```
Listener → Backend Pool → Backend Settings
```

Key action here:

### Host Name Override

Gateway replaces:

```
Host: <Gateway-IP>
```

with:

```
Host: appservice-xyz.azurewebsites.net
```

Why:

Azure App Service routes traffic using hostname matching.

Without rewrite:

```
Backend Health = Unhealthy
```

---

## Step 4 — Gateway Adds Forwarded Headers

Gateway injects headers before forwarding:

```
X-Forwarded-For: <Client-IP>
X-Forwarded-Proto: https
X-Client-IP: <Client-IP>
```

These headers preserve original user identity.

---

## Step 5 — Gateway Sends Request to App Service

Connection details:

```
Protocol: HTTP
Port: 80
Destination: App Service Front-End
```

Traffic never goes directly to container.

It first hits Azure’s App Service platform layer.

---

# 3. Inside Azure App Service Platform

---

## Step 6 — App Service Front-End Receives Request

Azure platform receives request and inspects:

```
Host Header → appservice-xyz.azurewebsites.net
```

The front-end determines:

```
Which App Service instance owns this hostname.
```

Then forwards request to the correct worker node.

---

## Step 7 — Azure Adds Platform Headers

Before forwarding internally, Azure adds:

```
X-Arr-Ssl
X-Site-Deployment-Id
X-Original-Url
Disguised-Host
```

These confirm:

* Traffic passed through Azure routing layer
* SSL info recorded
* Original request preserved

---

## Step 8 — Worker Node Receives Traffic

Worker node hosts your container.

Azure reverse proxy performs:

```
External Port 80 → Internal Container Port
```

This mapping is determined by:

```
WEBSITES_PORT environment variable
```

Example:

```
WEBSITES_PORT = 8080
```

Azure builds a tunnel:

```
Host Machine Port 80 → Container Port 8080
```

---

# 4. Container-Level Traffic

---

## Step 9 — Docker Port Bridge

Inside worker node:

```
App Service Proxy
        |
        v
localhost:8080 (container)
```

Docker container receives:

```
GET / HTTP/1.1
Host: appservice-xyz.azurewebsites.net
```

Your Go application finally processes request.

---

## Step 10 — Go Application Sees Full Header Set

Headers visible inside container:

```
X-Forwarded-For
X-Forwarded-Proto
X-Arr-Ssl
X-Client-IP
Disguised-Host
```

Meaning:

* Client IP preserved
* TLS confirmed externally
* Azure routing path traceable

---

# 5. Response Path (Reverse Flow)

When Go app responds:

```
Go Container → Worker Node → App Service Front-End → Application Gateway → Laptop
```

Application Gateway does:

```
HTTP Response → Re-Encrypt → HTTPS Response
```

Browser receives secure response.

---

# 6. Real Port Transformation

| Stage                   | Protocol | Port |
| ----------------------- | -------- | ---- |
| Laptop → Gateway        | HTTPS    | 443  |
| Gateway → App Service   | HTTP     | 80   |
| App Service → Container | HTTP     | 8080 |

---

# 7. Why HTTPS Only Must Be OFF on App Service

If enabled:

* App Service forces HTTPS redirect
* Gateway already terminated TLS
* Redirect loop occurs

Result:

```
Browser jumps to azurewebsites.net:80
```

Correct configuration:

```
TLS handled ONLY at Gateway
```

---

# 8. Access Restriction Flow

After validation:

Restrict App Service inbound traffic:

```
Allow Service Tag:
AzureApplicationGateway
```

Effect:

```
Internet → Gateway → App Service ✔
Direct Internet → App Service ✖
```

---

# 9. Real Header Ownership

| Header               | Added By             |
| -------------------- | -------------------- |
| X-Forwarded-For      | Application Gateway  |
| X-Forwarded-Proto    | Application Gateway  |
| X-Arr-Ssl            | App Service Platform |
| X-Site-Deployment-Id | App Service          |
| Disguised-Host       | Azure Routing Layer  |

---

# 10. Complete Lifecycle Summary

```
Laptop
  ↓ HTTPS 443
Application Gateway
  ↓ TLS Decrypt
  ↓ Host Rewrite
  ↓ Adds Forward Headers
App Service Front-End
  ↓ Platform Routing
Worker Node
  ↓ Port Bridge
Docker Container
  ↓
Go Application
```

---

# 11. Key DevOps Observations

* TLS termination reduces backend load.
* Host rewrite is mandatory for App Service targets.
* WEBSITES_PORT prevents container routing issues.
* Gateway headers maintain original client context.
* Access Restrictions enforce zero-trust edge entry.

---

# 12. Final Mental Model

Think of the request as a **baton pass**:

1. Browser passes encrypted baton to Gateway.
2. Gateway unwraps baton and adds labels.
3. App Service reads label and chooses correct worker.
4. Docker bridge hands baton into container.
5. Go app reads everything written along the journey.

---
