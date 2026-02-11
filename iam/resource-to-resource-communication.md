# Azure Managed Identity Token Retrieval using curl

## 🎯 Goal

This guide demonstrates how to obtain an **OAuth access token** from the
Azure Instance Metadata Service (IMDS) using `curl`, and use it to
access Azure Storage securely without secrets.

This method is typically used when:

-   A Virtual Machine has **Managed Identity** enabled
-   Workloads need secure access to Azure resources
-   You want passwordless authentication

------------------------------------------------------------------------

## 🧱 Architecture Overview

    Azure VM (Managed Identity Enabled)
            ↓
    Instance Metadata Service (169.254.169.254)
            ↓
    Microsoft Entra ID Token
            ↓
    Azure Storage (RBAC Authorization)

------------------------------------------------------------------------

## ✅ Prerequisites

-   VM running in Azure
-   System Assigned Managed Identity enabled
-   RBAC role assigned on Storage Account
    -   Example: Storage Blob Data Reader
-   `curl` installed
-   `jq` installed

Install jq if needed:

``` bash
sudo apt install jq -y
```

------------------------------------------------------------------------

## Step 1 --- Request Access Token using curl

Run this **inside the Azure VM**:

``` bash
curl -H "Metadata: true" "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://storage.azure.com/" -s
```

### 🔎 Explanation

-   `Metadata: true` → Required security header
-   `api-version` → Metadata service API version
-   `resource` → Target service (Azure Storage)

------------------------------------------------------------------------

## Step 2 --- Extract Access Token using jq

``` bash
curl -H "Metadata: true" "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://storage.azure.com/" -s | jq -r .access_token
```

### Important

Notice the `.` before `access_token` --- required for JSON parsing.

------------------------------------------------------------------------

## Step 3 --- Store Token in Variable

``` bash
TOKEN=$(curl -H "Metadata: true" "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://storage.azure.com/" -s | jq -r .access_token)
```

Verify token length:

``` bash
echo $TOKEN | wc -c
```

------------------------------------------------------------------------

## Step 4 --- Call Azure Storage API using Token

Example: List containers

``` bash
curl -H "Authorization: Bearer $TOKEN" "https://<storage-account>.blob.core.windows.net/?comp=list"
```

If RBAC permissions are correct, container list will be returned.

------------------------------------------------------------------------

## 🧠 Key Concepts

-   Managed Identity removes need for secrets or keys
-   IMDS endpoint exists only inside Azure resources
-   Tokens are short-lived and automatically rotated
-   Azure RBAC controls actual authorization

------------------------------------------------------------------------

## ⚠️ Common Errors

### identity not found

Managed Identity is not enabled on VM.

### 403 AuthorizationFailure

RBAC role missing on Storage Account.

### Empty token output

Wrong resource URL or missing header.

### jq error

jq is not installed or filter missing leading dot.

------------------------------------------------------------------------

## 🚀 Easier Alternative (Azure CLI)

Instead of curl:

``` bash
az login --identity
az storage container list --account-name <name> --auth-mode login
```

Azure CLI automatically handles token retrieval.

------------------------------------------------------------------------

## 🔐 Security Notes

-   Never store tokens permanently
-   Tokens expire (\~1 hour)
-   Prefer Managed Identity over client secrets

------------------------------------------------------------------------

## 📌 One-line Summary

Managed Identity allows Azure VMs to securely request OAuth tokens from
the metadata service and access Azure resources using RBAC without
storing credentials.