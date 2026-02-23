resource "azurerm_postgresql_flexible_server" "db" {
  name                = "my-lab-psql-server"
  resource_group_name = azurerm_resource_group.hub_spoke_rg.name
  location            = azurerm_resource_group.hub_spoke_rg.location
  version             = "17"

  # Pointing to the subnet and private DNS zone
  delegated_subnet_id = azurerm_subnet.db_subnet.id
  private_dns_zone_id = azurerm_private_dns_zone.postgres_dns.id

  public_network_access_enabled = false
  administrator_login           = "psqladmin"
  administrator_password        = var.database_password

  sku_name   = "B_Standard_B1ms"
  storage_mb = 32768
  zone       = "1"
  # This ensures the DNS link is ready before the DB tries to use it
  depends_on = [azurerm_private_dns_zone.postgres_dns]
}