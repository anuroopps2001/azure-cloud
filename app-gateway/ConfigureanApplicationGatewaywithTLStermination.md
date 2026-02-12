# Azure Application Gateway: Pro Setup (SSL Termination & Redirection)

This guide covers the configuration of a production-ready Application Gateway that forces all traffic to HTTPS and routes it to a custom backend port (4444) secured by an Application Security Group (ASG).

---

## 1. Prerequisites
- [x] **Self-Signed Certificate**: A `.pfx` file (e.g., `appgw.pfx`).
- [x] **Application Security Group (ASG)**: Created and associated with backend VMs.
- [x] **Nginx Configuration**: Backends must be listening on Port `4444`.
- [x] **NSG Rule**: Inbound traffic allowed from Gateway Subnet to ASG on Port `4444`.

---

---
Visit the [Markdown Guide](https://learn.microsoft.com/en-us/azure/application-gateway/create-ssl-portal) for Creating AppGateway.
---

## 2. Step-by-Step Configuration

### A. The Secure Listener (HTTPS)
*The "Hostess" that handles encrypted traffic.*
1. Go to **Listeners** > **+ Add listener**.
2. **Name**: `https-listener`
3. **Frontend IP**: `Public`
4. **Protocol**: `HTTPS` (Port `443`)
5. **Certificate**: Choose **Upload a certificate**, select your `.pfx` file, and provide the password.
6. **Listener Type**: `Basic`

### B. The Bouncer Listener (HTTP)
*The "Signpost" that catches insecure traffic.*
1. Go to **Listeners** > **+ Add listener**.
2. **Name**: `http-listener`
3. **Frontend IP**: `Public`
4. **Protocol**: `HTTP` (Port `80`)
5. **Listener Type**: `Basic`

### C. Backend Settings (The Translator)
*Tells the Gateway to talk to Nginx on 4444 via HTTP.*
1. Go to **Backend settings** > **+ Add**.
2. **Name**: `settings-nginx-4444`
3. **Protocol**: `HTTP`
4. **Port**: `4444`
5. **Request time-out**: `20 seconds`
6. **Custom probe**: Select your custom health probe (configured for port 4444).

### D. The Main Routing Rule (Secure Path)
1. Go to **Rules** > **+ Request routing rule**.
2. **Name**: `rule-https-to-backend`
3. **Listener**: `https-listener`
4. **Backend targets**:
    * **Target type**: `Backend pool`
    * **Backend target**: Select your VM pool.
    * **Backend settings**: `settings-nginx-4444`

### E. The Redirection Rule (The "Bouncer" Logic)
1. Go to **Rules** > **+ Request routing rule**.
2. **Name**: `rule-http-to-https-redirect`
3. **Listener**: `http-listener`
4. **Backend targets**:
    * **Target type**: `Redirection`
    * **Redirection type**: `Permanent (301)`
    * **Redirection target**: `Listener`
    * **Target listener**: `https-listener`
    * **Include path**: `Yes`
    * **Include query string**: `Yes`

---

## 3. Traffic Logic Flow



1. **User Request**: User hits `http://<Public-IP>`.
2. **Listener 80**: Catches the request and triggers the Redirection Rule.
3. **Redirection**: Gateway sends a `301 Moved Permanently` response to the user's browser.
4. **User Re-request**: Browser automatically hits `https://<Public-IP>`.
5. **Listener 443**: Catches the secure request, decrypts the SSL, and passes it to the Backend Pool on **Port 4444**.

---

## 4. Verification Commands
Run these to verify the setup is working without using a browser:

```bash
# 1. Test the HTTP Redirection (Should see a 301 response)
curl -I http://<Your-AppGW-Public-IP>

# 2. Test the HTTPS Path (Should see the Nginx welcome page)
# Use -k to ignore self-signed certificate warnings
curl -k https://<Your-AppGW-Public-IP>
```

