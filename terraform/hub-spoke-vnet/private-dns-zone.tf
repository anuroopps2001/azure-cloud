resource "azurerm_private_dns_zone" "postgres_dns" {
  name                = "privatelink.postgres.database.azure.com" # Resource is created with the domain name
  resource_group_name = azurerm_resource_group.hub_spoke_rg.name
}


# Link the DNS zone to Vnets
# 1. Link to hub vnet
resource "azurerm_private_dns_zone_virtual_network_link" "hub_link" {
  name                  = "hub-dns-link"
  resource_group_name   = azurerm_resource_group.hub_spoke_rg.name
  virtual_network_id    = azurerm_virtual_network.vnets["hub"].id
  private_dns_zone_name = azurerm_private_dns_zone.postgres_dns.name # Name of Private DNS zone to which vnet is being linked
}

# 2. Link Zone to spoke vnet
resource "azurerm_private_dns_zone_virtual_network_link" "spoke_link" {
  resource_group_name   = azurerm_resource_group.hub_spoke_rg.name
  virtual_network_id    = azurerm_virtual_network.vnets["spoke"].id
  private_dns_zone_name = azurerm_private_dns_zone.postgres_dns.name
  name                  = "spoke-dns-link"
}