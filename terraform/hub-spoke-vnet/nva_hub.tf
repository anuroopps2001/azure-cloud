resource "azurerm_network_interface" "nva_nic" {
  name                = "nva-nic"
  location            = azurerm_resource_group.hub_spoke_rg.location
  resource_group_name = azurerm_resource_group.hub_spoke_rg.name

  ip_forwarding_enabled = true

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.hub_mgmt.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.100.1.4"
  }
}

# Simple Linux VM as the NVA
resource "azurerm_linux_virtual_machine" "nva" {
  name                  = "nva-hub"
  resource_group_name   = azurerm_resource_group.hub_spoke_rg.name
  location              = azurerm_resource_group.hub_spoke_rg.location
  size                  = "Standard_B2ats_v2"
  admin_username        = "adminuser"
  network_interface_ids = [azurerm_network_interface.nva_nic.id]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("C:\\Users\\ANUROOP P S\\.ssh\\id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}