resource "azurerm_resource_group" "hub_spoke_rg" {
  name     = "rg-hubspoke-terraform"
  location = "centralindia"
}