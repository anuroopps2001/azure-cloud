# Tell the Spoke Subnet: "If you want to talk to the Hub's Database range, you must go through the NVA first."
resource "azurerm_route_table" "spoke_rt" {
  name                = "rt-spoke-to-hub"
  location            = azurerm_resource_group.hub_spoke_rg.location
  resource_group_name = azurerm_resource_group.hub_spoke_rg.name

  route {
    name                   = "ToHubDatabase"
    address_prefix         = "10.100.2.0/24" # Hub subnet
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.100.1.4"
  }
}

# Associate route table with the spoke client subnet
resource "azurerm_subnet_route_table_association" "spoke_assoc" {
  subnet_id      = azurerm_subnet.spoke_workload.id
  route_table_id = azurerm_route_table.spoke_rt.id
}


# This forces the App Service Subnet to use the NVA as the gateway
resource "azurerm_subnet_route_table_association" "app_subnet_assoc" {
  subnet_id      = azurerm_subnet.spoke_app_integration.id
  route_table_id = azurerm_route_table.spoke_rt.id
}