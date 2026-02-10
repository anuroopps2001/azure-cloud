## 1. Azure CLI Authentication

Before managing resources, the CLI session must be authenticated against the Azure Resource Manager (ARM).

### Authentication Steps:
1. **Interactive Login:** Execute `az login`.
2. **Identity Verification:** Confirm the correct `cloudName` (usually `AzureCloud`) and `tenantId`.
3. **Subscription Selection:** Use `az account set` to ensure the context is set to the correct billing account.

> **Security Note:** In a CI/CD pipeline (like GitHub Actions or Azure DevOps), we don't use `az login` with a browser. Instead, we use a **Service Principal** (a "bot" account) with a secret key.

## 2. Managing Active Subscriptions

The Azure CLI uses a "Default Context." If a command to list VMs or Storage accounts returns empty, verify the active subscription.

### Essential Commands:
* **Check Active:** `az account show -o table`
* **List All Access:** `az account list -o table`
* **Switch Context:** `az account set --subscription <name_or_id>`

### DevOps Tip:
If you find yourself switching constantly, you can set an environment variable or use the `--subscription` flag directly on any command to override the default temporarily:
`az vm list --subscription "Secondary-Sub" -o table`


## 3. The Azure Logical Hierarchy

Understanding the "Nested" nature of Azure is critical for resource lifecycle management and security (RBAC).

### The Structural Flow:
1.  **Tenant (Entra ID):** The top-level identity boundary.
2.  **Subscription:** The billing boundary (Equiv. to an AWS Account).
3.  **Resource Group (RG):** The management boundary. 
    * *Note:* Unlike AWS, Azure uses RGs as the primary unit for grouping resources with the same lifecycle.
4.  **Resources:** The actual assets (VMs, SQL DBs, VNETs).

### Why the Resource Group (RG) is unique:
* **Lifecycle:** Delete the RG, delete the project. No "orphaned" disks left behind!
* **Access:** You can give a developer "Owner" rights to one RG without letting them touch the rest of the Subscription.
* **Metadata:** You can apply tags to an RG, and while they don't automatically inherit, it makes searching much easier.

## 4. Regional Architecture: Resources vs. Resource Groups

A common misconception is that a Resource Group acts as a physical boundary. It is actually a **Logical Boundary** with a **Metadata Location**.

### Key Rules:
* Creating an Resource Group in `eastus` location
```bash
$ az group create --name Dev-Project-RG --location eastus
```
* **The Metadata Rule:** The `--location` flag on an RG defines where the *description* of your resources is stored.
* **The Flexibility Rule:** Resources (VMs, VNETs) can reside in any region, regardless of their parent Resource Group's location.
* **The "Blast Radius" Caveat:** If the RG's region is offline, management operations (Start/Stop/Delete) on resources within that RG may fail, even if the resources are in a healthy region.

### Best Practice:
Unless you have a specific compliance reason, **always place the Resource Group in the same region as your primary resources** to minimize management dependencies.

## 5. Listing sshkeys and querying the json output using --query and jq

* `--query` is for azure cli and works well with `-o table` and `-o tsv`
* jq is also used to parse the json output based on requirements
```bash
az>> az sshkey list -o json
[
  {
    "id": "/subscriptions/11fae606-7310-4eda-9223-b28e981ae28c/resourceGroups/DEV-PROJECT-RG/providers/Microsoft.Compute/sshPublicKeys/myVm_key",
    "location": "centralindia",
    "name": "myVm_key",
    "publicKey": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC2ECw3nX8+qwzX63uycWEJwEVs7UGYScKm3+kuqtdeT6TC5Xk+06YLPG7NPBUXWrWV0wIQoH83bKwUtEEyAkghwzSpXMMyG8GVcZQ0L+HjczKvlPw5plrg5YFZIHwm72ypTVS/bm+tKm8wm9hdi7Pwy6Jxg0fMJ+fNeG4lJRVo8vRF9MJjzFMGRnJ/Vu9RR8pVepE9nNFaQgj5cP3bJ13dt+hOvxg9RNBaaXJjsJOt8joxDfrVm23PwD4s+0GdIGTX1pQ9I83ISWrB1nipPPu8dS/jUGx3t2z94Aj+miRUK438H+ivvtk2LnlxghOfzFUWIfnTKaBlIDz4JTx+orQp6M54t6e6/0J/zmQvEFulHWjycnLhBZeELwzNblNYLY9svdIhdDZzPvt7Yge1p2fY283YIiwE3EqvNOKTH3TSw/XY5O1hqbq/BJQeYLKHLNu3pgJUYxWhlEaxBIdIwpGFJbhDN4cae1F0zeTvob8JVQkO+ifdGVe6uOL5iVskXR0= generated-by-azure",
    "resourceGroup": "DEV-PROJECT-RG",
    "tags": {},
    "type": null
  }
]
az>> az sshkey list -o json | jq
'jq' is not recognized as an internal or external command,
operable program or batch file.
az>> az sshkey list --query "[].name" -o tsv
myVm_key
az>> az sshkey list --query "[].{name:name, rg:resourceGroup" -o tsv
argument --query: invalid jmespath_type value: '[].{name:name, rg:resourceGroup'
To learn more about --query, please visit: 'https://learn.microsoft.com/cli/azure/query-azure-cli'
az>> az sshkey list --query "[].{name:name, rg:resourceGroup}" -o tsv
myVm_key        DEV-PROJECT-RG
az>> az sshkey list --query "[].{name:name, rg:resourceGroup, key:publicKey}" -o tsv
myVm_key        DEV-PROJECT-RG  ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC2ECw3nX8+qwzX63uycWEJwEVs7UGYScKm3+kuqtdeT6TC5Xk+06YLPG7NPBUXWrWV0wIQoH83bKwUtEEyAkghwzSpXMMyG8GVcZQ0L+HjczKvlPw5plrg5YFZIHwm72ypTVS/bm+tKm8wm9hdi7Pwy6Jxg0fMJ+fNeG4lJRVo8vRF9MJjzFMGRnJ/Vu9RR8pVepE9nNFaQgj5cP3bJ13dt+hOvxg9RNBaaXJjsJOt8joxDfrVm23PwD4s+0GdIGTX1pQ9I83ISWrB1nipPPu8dS/jUGx3t2z94Aj+miRUK438H+ivvtk2LnlxghOfzFUWIfnTKaBlIDz4JTx+orQp6M54t6e6/0J/zmQvEFulHWjycnLhBZeELwzNblNYLY9svdIhdDZzPvt7Yge1p2fY283YIiwE3EqvNOKTH3TSw/XY5O1hqbq/BJQeYLKHLNu3pgJUYxWhlEaxBIdIwpGFJbhDN4cae1F0zeTvob8JVQkO+ifdGVe6uOL5iVskXR0= generated-by-azure
az>>

$ az sshkey list --query "[].name" -o tsv
$ az sshkey list -o json | jq -r '.[].name'
$ az sshkey list -o json | jq '.[] | {keyName: .name, region: .location}'
```

## 5. NetworkWatcher RG per region



## 6. Azure Identity and Access Management (IAM) Reference Guide

## 1. Core Identity Components
In Azure, permissions are built on three pillars: **Who**, **What**, and **Where**.

### A. The "Who" (Security Principals)
* **Users:** Individual people (e.g., `yourname@company.com`).
* **Groups:** Collections of users. 
    * *Best Practice:* Always assign roles to **Groups**, not users. It makes onboarding/offboarding much faster.
* **Service Principals:** An identity for an application or service that exists *outside* of Azure (e.g., GitHub Actions, On-prem servers).
* **Managed Identities:** The most secure identity for *internal* Azure resources (e.g., a VM). It eliminates the need for passwords/secrets.

### B. The "What" (Roles)
* **Control Plane Roles:** Manage the resource itself (e.g., "Contributor" can delete a Storage Account).
* **Data Plane Roles:** Manage the data *inside* the resource (e.g., "Storage Blob Data Reader" can read the actual files inside).

### C. The "Where" (Scope)
Roles can be assigned at different levels of the hierarchy. Permissions "flow down" from the top:
1.  **Management Group** (Multiple Subscriptions)
2.  **Subscription**
3.  **Resource Group**
4.  **Resource** (Single Storage Account or VM)

---

## 2. Service-to-Service Communication Flow
This is the "Passwordless" method used for one Azure resource to talk to another.

### The Mechanism
1.  **Enable Identity:** Enable "System-Assigned Managed Identity" on the **Source** (e.g., Jenkins VM).
2.  **Assign Role:** On the **Destination** (e.g., Production Storage), add a Role Assignment for that VM's Identity.
3.  **Request Token:** The Source resource calls the **Instance Metadata Service (IMDS)** at `http://169.254.169.254`.
4.  **Present Token:** The Source sends a `curl` or API request with the `Authorization: Bearer <token>` header.



---

## 3. Comparison: Service Principal vs. Managed Identity

| Feature | Service Principal | Managed Identity |
| :--- | :--- | :--- |
| **Credentials** | Client ID & Client Secret | **None** (Handled by Azure) |
| **Rotation** | Manual / Scripted | **Automatic** |
| **Use Case** | Apps outside Azure | Apps inside Azure |
| **Security Risk** | Secret can be leaked or expire | **Zero** credential leak risk |

---

## 4. Why the Access Token is Required
Even if you have assigned a Role to a VM, you still need a **Token** for every request because:

1.  **Proof of Identity:** The token is a signed digital certificate proving the request isn't "spoofed."
2.  **Temporary Access:** Tokens expire (usually after 24 hours). This limits the "blast radius" if a session is compromised.
3.  **Statelessness:** The destination (Storage) doesn't need to check Azure AD for every single packet; it simply verifies the signature on the token you provided.



---

## 5. Common Resource-to-Resource Roles

| Destination Service | Recommended Role |
| :--- | :--- |
| **Storage Account** | `Storage Blob Data Reader` / `Contributor` |
| **Key Vault** | `Key Vault Secrets User` |
| **Service Bus** | `Azure Service Bus Data Receiver` |
| **App Configuration** | `App Configuration Data Reader` |

---
*Note: Managed Identity is the standard for modern Azure architecture to achieve a "Zero Trust" environment.*


### Steps to provide an storageAccount access to VM in Azure
```bash
To give your VM access to a specific storage account:

Navigate to your Storage Account in the Azure Portal.

Click on Access Control (IAM) in the left-hand sidebar.

Click + Add and select Add role assignment.

Role: Search for Storage Blob Data Reader (or Contributor if you need to upload).

Assign access to: Select Managed identity.

Members: Click + Select members, find your VM's name, and select it.

Review + assign: Save the changes.
```


**We can actually choose how "broad" this permission is by where you click the IAM button:**

* At the Storage Account: VM can access every container in that specific account.

* At the Resource Group: VM can access every storage account inside that RG.

* At the Container level: VM can only access one specific folder/container inside the storage account.

*With CLI*
```bash
# Get the Principal ID of your VM
$ principal_id=$(az vm identity show --name managed-identity-vm --resource-group managed-identity-vm_group --query principalId)


# Assign the "Reader" role to that VM for the specific Storage Account
$ az role assignment create \
    --assignee "$principal_id" \
    --role "Storage Blob Data Reader" \
    --scope "/subscriptions/YOUR_SUB_ID/resourceGroups/YourRG/providers/Microsoft.Storage/storageAccounts/YourStorageAccountName"
```

## 6.1 The Three Main Identities
* **User Identity**: You. Your email address.

* **Service Principal**: A "Ghost User." It has a username (Client ID) and a password (Secret). You use this for apps living outside Azure.

* **Managed Identity**: A "Robot Identity." The robot (VM) is the ID. No password needed. You use this for apps living inside Azure.

## 6.2 How they connect (The 3-Step Logic)
* **The Subject (Principal ID)**: The VM or User.
* **The Permission (Role)**: "Contributor" or "Reader."
* **The Target (Scope)**: The Storage Account or Resource Group.