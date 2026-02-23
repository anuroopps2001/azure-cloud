# HUB Subnets
# 1. For NVA VM
resource "azurerm_subnet" "hub_mgmt" {
  resource_group_name  = azurerm_resource_group.hub_spoke_rg.name
  name                 = "snet-hub-mgmt"
  virtual_network_name = azurerm_virtual_network.vnets["hub"].name
  address_prefixes     = ["10.100.1.0/24"]
}

# 2. For Postgres flexi server
resource "azurerm_subnet" "db_subnet" {
  name                 = "snet-db"
  resource_group_name  = azurerm_resource_group.hub_spoke_rg.name
  virtual_network_name = azurerm_virtual_network.vnets["hub"].name
  address_prefixes     = ["10.100.2.0/24"]

  # with delegation, keeping the subnet specifically for postgresl flexi servers
  delegation {
    name = "fs"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}


# SPOKE Subnets
# 1. For VM
resource "azurerm_subnet" "spoke_workload" {
  resource_group_name  = azurerm_resource_group.hub_spoke_rg.name
  name                 = "snet-spoke-workload"
  virtual_network_name = azurerm_virtual_network.vnets["spoke"].name
  address_prefixes     = ["10.50.1.0/24"]
}

# 2. Appservice subnet
resource "azurerm_subnet" "spoke_app_integration" {
  name                 = "snet-spoke-app-int"
  resource_group_name  = azurerm_resource_group.hub_spoke_rg.name
  virtual_network_name = azurerm_virtual_network.vnets["spoke"].name
  address_prefixes     = ["10.50.2.0/24"] # New range
  # We cannot "add" a delegation to a subnet if there are already active resources 
  # (like VM's NIC) sitting in it.
  delegation {
    name = "app-delegation"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}