# 🌐 Azure Networking: Integration vs. Injection vs. Private Endpoint

This section documents the networking architecture used to bridge our **Multi-tenant PaaS** (App Service) and **VNet-Native** (PostgreSQL) resources.

## 1. Summary of Concepts

| Concept | Direction | Residency | Description |
| :--- | :--- | :--- | :--- |
| **VNet Injection** | Inbound/Outbound | **Inside** | Resource is born in the VNet (e.g., PostgreSQL Flex). |
| **VNet Integration** | **Outbound** | **Outside** | The "Exit Bridge" for PaaS Services to reach the VNet. |
| **Private Endpoint** | **Inbound** | **Outside** | The "Front Door" for VNet resources to reach the PaaS Services. |

---

## 2. Detailed Patterns

### 💉 VNet Injection (The "Resident")
**VNet-Native** resources are deployed directly into a subnet.
* **Architecture:** The resource receives a private IP (e.g., `10.50.2.4`) from your address space.
* **Security:** Governed by Network Security Groups (NSGs) and Route Tables (UDR) on the subnet.
* **Example:** Our **PostgreSQL Flexible Server** is injected into the database subnet.

### 🌉 VNet Integration (The "Exit Bridge")
Used because **non-VNet-native** are PaaS mostly.
* **Architecture:** Connects the PaaS to a dedicated subnet. This allows the app's code to "reach out" to the VNet.
* **Use Case:** Allows our PaaS to talk to the **PostgreSQL** private IP.
* **Perspective:** From the PaaS's view, this is **Outbound** traffic.

### 🚪 Private Endpoint (The "Front Door")
Provides a private entry point for the PaaS.
* **Architecture:** Creates a Network Interface (NIC) in your VNet.
* **Use Case:** Allows a **Vnet-native** resources to access the PaaS Services via a private IP instead of the public internet.
* **Perspective:** From the PaaS service's view, this is **Inbound** traffic.

---

## 3. Visual Architecture



1. **Traffic Out:** `App Service(PaaS)` -> `VNet Integration` -> `VNet` -> `PostgreSQL (Injected) (Vnet-native)`
2. **Traffic In:** `VM (VNet)` -> `Private Endpoint` -> `App Service(PaaS)`

---

**PaaS services cannot be Vnet-native, because those are being managed by Azure**