# Azure App Registration Demo (Step‑by‑Step)

## 🎯 Goal

This lab demonstrates how an **App Registration** in Microsoft Entra ID
works like a workload identity (similar to a service account).\
You will:

-   Create an App Registration
-   Understand the Service Principal
-   Assign RBAC permissions
-   Authenticate using Azure CLI

------------------------------------------------------------------------

## 🧱 Architecture Overview

    App Registration (identity definition)
            ↓
    Service Principal (actual identity used for RBAC)
            ↓
    Role Assignment (Contributor / Reader / etc.)
            ↓
    Azure Resources (Subscriptions / Resource Groups)

------------------------------------------------------------------------

## Step 1 --- Create App Registration

1.  Go to **Microsoft Entra ID → App registrations**
2.  Click **New registration**
3.  Enter:

```{=html}
<!-- -->
```
    Name: dev-deployer-app
    Supported account types: Single tenant
    Redirect URI: Leave empty

4.  Click **Register**

### ✅ What happened?

-   You created an identity definition.
-   Azure automatically created a **Service Principal** in Enterprise
    Applications.

------------------------------------------------------------------------

## Step 2 --- Verify Service Principal

Navigate to:

    Microsoft Entra ID → Enterprise Applications

Search for:

    dev-deployer-app

This is the identity that Azure RBAC actually uses.

### 💡 Important Concept

App Registration = blueprint\
Service Principal = usable identity

------------------------------------------------------------------------

## Step 3 --- Create Client Secret (Authentication Credential)

Inside the App Registration:

    Certificates & Secrets → New client secret

Provide:

    Description: lab-secret

Click **Add** and copy:

-   Client ID
-   Tenant ID
-   Client Secret VALUE (save immediately)

These act like login credentials for the application.

------------------------------------------------------------------------

## Step 4 --- Assign RBAC Role

Go to:

    Subscriptions → dev-sub → Access Control (IAM)

Click:

    Add → Add role assignment

Select:

    Role: Contributor
    Assign access to: User, group, or service principal
    Select: dev-deployer-app

### ✅ Result

The application identity can now manage resources in dev-sub.

------------------------------------------------------------------------

## Step 5 --- Login Using Azure CLI

Use the credentials created earlier:

``` bash
az login --service-principal   --username <CLIENT_ID>   --password <CLIENT_SECRET>   --tenant <TENANT_ID>
```

Verify login:

``` bash
az account show
```

------------------------------------------------------------------------

## Step 6 --- Test Permissions

Run:

``` bash
az group list --output table
```

If it works, RBAC is correctly configured.

------------------------------------------------------------------------

## 🧠 Key Concepts Learned

-   App Registration defines an application identity.
-   Service Principal is the runtime identity used for RBAC.
-   Client Secret is an authentication method.
-   RBAC roles control what the app can do.

------------------------------------------------------------------------

## ⚠️ Common Mistakes

-   Assigning roles to users instead of the service principal
-   Forgetting to copy the client secret value
-   Granting Owner role unnecessarily
-   Confusing Enterprise Applications with App Registrations

------------------------------------------------------------------------

## ✅ Real‑World Use Cases

-   Terraform automation
-   CI/CD pipelines
-   Backend APIs accessing Azure resources
-   GitHub Actions deployments

------------------------------------------------------------------------

## 🚀 Next Practice Ideas

-   Create a second app with Reader role on prod-sub
-   Compare access behavior between two app identities
-   Replace client secret with certificate authentication