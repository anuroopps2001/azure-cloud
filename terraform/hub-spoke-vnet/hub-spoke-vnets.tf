resource "azurerm_virtual_network" "vnets" {
  for_each            = var.vnet_data
  name                = "vnet-${each.key}"
  address_space       = [each.value]
  location            = azurerm_resource_group.hub_spoke_rg.location
  resource_group_name = azurerm_resource_group.hub_spoke_rg.name
}