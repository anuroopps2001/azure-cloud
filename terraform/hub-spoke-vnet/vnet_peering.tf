resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                      = "hub-to-spoke"
  resource_group_name       = azurerm_resource_group.hub_spoke_rg.name
  virtual_network_name      = azurerm_virtual_network.vnets["hub"].name
  remote_virtual_network_id = azurerm_virtual_network.vnets["spoke"].id

  depends_on = [azurerm_virtual_network.vnets] # make sure both the vnets present before peering
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                      = "spoke-to-hub"
  resource_group_name       = azurerm_resource_group.hub_spoke_rg.name
  virtual_network_name      = azurerm_virtual_network.vnets["spoke"].name
  remote_virtual_network_id = azurerm_virtual_network.vnets["hub"].id

  depends_on = [azurerm_virtual_network.vnets]
}