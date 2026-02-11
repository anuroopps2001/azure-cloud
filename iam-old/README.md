# Azure Architecture & Identity Master Guide

## 1. The Root: Microsoft Entra ID (The Tenant)
**Microsoft Entra ID** is the top-most level. It is the "Identity Provider" and the security boundary for your entire organization.

* **Role:** The "Building Manager."
* **Permissions:** Managed via **Entra ID Roles** (e.g., Global Administrator, Application Administrator).
* **Key Fact:** You can have multiple Subscriptions under one Tenant, but a Subscription can only trust one Tenant.



---

## 2. Management Groups (The Organizational Folders)
Used to manage policies and compliance across multiple subscriptions.

* **Purpose:** If you have 50 subscriptions, you can apply a single rule (e.g., "Only allow resources in Central India") at this level, and it trickles down to everything below.

---

## 3. Subscriptions (The Billing & Quota Boundary)
This is where the "Bank Account" lives. This is the level where you separate environments.

### The Professional Multi-Sub Model:
| Subscription Name | Purpose | Risk Level |
| :--- | :--- | :--- |
| **Dev_Subscription** | Sandboxing, testing, and learning. | High (Permissions are loose) |
| **PreProd_Subscription** | Staging and Quality Assurance. | Medium (Matches Prod config) |
| **Prod_Subscription** | Live customer-facing applications. | Low (Highly restricted access) |



---

## 4. Resource Groups (The Lifecycle Container)
A logical container for resources deployed on Azure.

* **Logic:** Resources inside a Resource Group should share the same lifecycle. If you delete the RG, everything inside is deleted.
* **Example:** `rg-payment-api-prod-01`
* **Identity Tip:** As an **Owner** of an RG, you can enable **Managed Identities** on VMs without needing Tenant-level permissions.

---

## 5. Resources (The Utility Layer)
The actual services that do the work.

* **Compute:** Virtual Machines, App Services.
* **Storage:** Storage Accounts, SQL Databases.
* **Networking:** VNETs, Public IPs, NSGs.



---

## 6. Summary of Identity vs. Resource Roles

| Level | Role Type | Example Role | What it controls |
| :--- | :--- | :--- | :--- |
| **Tenant** | **Entra ID Role** | Global Admin | Users, Groups, App Registrations. |
| **Subscription** | **Azure RBAC** | Owner | Billing and ALL resources in that sub. |
| **Resource Group** | **Azure RBAC** | Contributor | Only the resources in that folder. |
| **Resource** | **Azure RBAC** | Reader | Just that specific VM or Disk. |

---

## 7. Quick Commands for Navigation

### Switch between Subscriptions:
```bash
# List all subscriptions you have access to
az account list --output table

# Set the active subscription to Dev
az account set --subscription "Dev_Subscription"
```

## 8. Managing Users and Access (RBAC)

### Level: The Tenant (Who is the person?)
- **Action:** Create the user in **Microsoft Entra ID**.
- **Role:** No roles are needed here yet (they are just a 'User' in the directory).

### Level: The Subscription (What can they do?)
- **Action:** Go to the Subscription -> **Access Control (IAM)** -> **Add Role Assignment**.
- **The "Big Three" Roles:**
    1. **Owner:** Full access, including giving access to others.
    2. **Contributor:** Full access to resources, but cannot manage permissions.
    3. **Reader:** Can only view resources.

### Best Practice: The Principle of Least Privilege
Always give users the *minimum* access they need to do their job. 
- Give developers **Contributor** on `Dev`.
- Give developers **Reader** on `Prod`.


## 9. The Wall: Azure RBAC vs. Microsoft Entra ID Roles

There is a hard wall between **Resources** and **Identities**.

### The Identity Side (Entra ID)
- **Top Level:** Tenant
- **Key Roles:** Global Administrator, User Administrator.
- **Powers:** Can create Users, Groups, and Service Principals. They manage "Who exists."

### The Resource Side (Azure RBAC)
- **Top Level:** Subscription
- **Key Roles:** Owner, Contributor.
- **Powers:** Can manage VMs, Databases, and assign permissions to *existing* people. They manage "What those people can do."

> **Crucial Note:** A Subscription Owner can assign a role to a user, but they cannot create the user. If the user doesn't exist in the Tenant, the Subscription Owner is powerless to add them.

## 10. Comparative Analysis: Office Account vs. Personal Account

### Scenario A: The Office Account (R Systems)
- **Identity Role:** User (Standard Member/Guest).
- **Subscription Role:** Owner.
- **Limitation:** Can manage everything *inside* the subscription, but cannot create "Who" (Service Principals/Users) in the Tenant.
- **Workflow:** Must request IT to create Service Principals or use **Managed Identities** to bypass the need for Tenant-level writes.

### Scenario B: The Personal Account (Your Lab)
- **Identity Role:** Global Administrator.
- **Subscription Role:** Owner.
- **Power:** Total control. Can create the "Who" (Users/Apps) and the "What" (VMs/Storage).
- **Workflow:** Direct creation of Service Principals via `az ad sp create-for-rbac`.

```bash
Microsoft Entra ID (Identity & Access)
        ↓
Management Groups (optional)  : It;s a collection of subscriptions
        ↓
Subscriptions
        ↓
Resource Groups
        ↓
Resources (VMs, VNets, etc.)
```

* To list all the subscriptions
```bash
$ az account list --output table
```

* Set the new active subscription:
```bash
$ az account set --subscription <sub_nameORsub_ID>
```
* Verify the change to confirm your current active subscription
```bash
$ az account show
```


* Querying the json output:
```bash
az>> az group list
[
  {
    "id": "/subscriptions/cc076e9a-89bc-4a47-86e4-09c6d0967bd8/resourceGroups/dev-rg",
    "location": "centralindia",
    "managedBy": null,
    "name": "dev-rg",
    "properties": {
      "provisioningState": "Succeeded"
    },
    "tags": {},
    "type": "Microsoft.Resources/resourceGroups"
  }
]
az>> az group list --query [].name
[
  "dev-rg"
]
az>> az group list --query [].{resoruceGroup:name}
[
  {
    "resoruceGroup": "dev-rg"
  }
]
az>> az group list --query [].{resoruceGroupLocation:location}
[
  {
    "resoruceGroupLocation": "centralindia"
  }
]
az>>
```

