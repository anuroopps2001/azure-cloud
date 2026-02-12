# Azure Architecture: Application Gateway with Private Nginx Backends

This document outlines the configuration for an Azure Application Gateway routing public traffic to backend VMs residing in a private subnet using a custom port.

---

## 1. Networking Layout
| Component | Subnet | IP Address |
| :--- | :--- | :--- |
| **Application Gateway** | `Subnet-A` (GatewaySubnet) | Public IP (Frontend) |
| **Backend VMs** | `Subnet-B` (BackendSubnet) | Private IP Only |

---

## 2. Security Configuration (NSG + ASG)
To keep the backend secure, we use an **Application Security Group (ASG)**.

### Application Security Group (ASG)
* **Name:** `asg-nginx-backends`
* **Association:** All Backend VM Network Interfaces (NICs).

### Network Security Group (NSG) Rules
Applied to `Subnet-B`:
| Priority | Name | Port | Source | Destination | Action |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 100 | `AllowAppGwInbound` | `4444` | `Subnet-A` Range | `asg-nginx-backends` | **Allow** |
| 65000 | `DenyAllInbound` | `Any` | `Any` | `Any` | **Deny** |

---

## 3. Application Gateway Configuration

### A. Listener (The Front Door)
* **Frontend IP:** Public
* **Protocol:** HTTP
* **Port:** `80` (Standard web port for users)

### B. Backend Settings (The Translator)
* **Target Port:** `4444`
* **Protocol:** HTTP
* **Custom Health Probe:** Required (Points to port `4444`)

### C. Routing Rule
* **Logic:** If traffic hits **Listener (Port 80)** → Apply **Backend Settings (Port 4444)** → Send to **Backend Pool**.

---

## 4. Backend VM Setup (Custom Script)
Run this script via **Custom Script Extension** to configure Nginx to listen on the custom port.

```bash
#!/bin/bash
# Install Nginx
apt-get update -y
apt-get install nginx -y

# Change default port from 80 to 4444
sed -i 's/listen 80 default_server;/listen 4444 default_server;/g' /etc/nginx/sites-available/default
sed -i 's/listen \[::\]:80 default_server;/listen \[::\]:4444 default_server;/g' /etc/nginx/sites-available/default

# Create status page for Health Probe
echo "Healthy" > /var/www/html/health.html

# Restart Nginx to apply changes
systemctl restart nginx
```

Visit the [Markdown Guide](https://learn.microsoft.com/en-us/azure/application-gateway/quick-create-portal) for more information.
