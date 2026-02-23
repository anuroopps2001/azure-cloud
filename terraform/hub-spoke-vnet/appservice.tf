# 1. THE SERVICE PLAN (Compute)
resource "azurerm_service_plan" "app_plan" {
  name                = "asp-spoke-hub"
  resource_group_name = azurerm_resource_group.hub_spoke_rg.name
  location            = azurerm_resource_group.hub_spoke_rg.location
  os_type             = "Linux"
  sku_name            = "B1"
}

# 2. THE LINUX WEB APP
resource "azurerm_linux_web_app" "web_app" {
  name                = "webapp-spoke-anuroopps-123"
  resource_group_name = azurerm_resource_group.hub_spoke_rg.name
  location            = azurerm_resource_group.hub_spoke_rg.location
  service_plan_id     = azurerm_service_plan.app_plan.id

  site_config {
    application_stack {
      docker_image_name        = "anuroop21/private-endpoint-python-app:v2"
      docker_registry_url      = "https://docker.io"
      docker_registry_username = "anuroop21"
      docker_registry_password = var.docker_password
    }
    # Important: This forces the app to use the VNet for these connections
    vnet_route_all_enabled = true
  }

  # VNET INTEGRATION: This allows, appservice (Outside VNet) to talk to resources in inside VNet
  virtual_network_subnet_id = azurerm_subnet.spoke_app_integration.id

  app_settings = {

    "AZURE_POSTGRESQL_HOST"   = "my-lab-psql-server.postgres.database.azure.com"
    "AZURE_POSTGRESQL_DBNAME" = "postgres"
    "AZURE_POSTGRESQL_DBUSER" = "psqladmin"
    "DB_PASSWORD"             = var.database_password
    "AZURE_POSTGRESQL_PORT"   = "5432"

    "WEBSITES_PORT" = "8000"


    # Optional: If you need to see Python errors in the browser for debugging
    "PYTHONENABLELOGGING" = "1"
  }
}