resource "azurerm_network_interface" "spoke_nic" {
  name                = "spoke-vm-nic"
  location            = azurerm_resource_group.hub_spoke_rg.location
  resource_group_name = azurerm_resource_group.hub_spoke_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.spoke_workload.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "spoke_vm" {
  name                  = "vm-spoke-client"
  resource_group_name   = azurerm_resource_group.hub_spoke_rg.name
  location              = azurerm_resource_group.hub_spoke_rg.location
  size                  = "Standard_B2ats_v2"
  admin_username        = "adminuser"
  network_interface_ids = [azurerm_network_interface.spoke_nic.id]

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