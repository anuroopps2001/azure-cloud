# output "vnet_configs" {
#   value = {
#     for k, v in azurerm_virtual_network.hub_spoke_vnet : k => v.ip_address_pool # Result: { hub = "id-123", spoke = "id-456" }
#   }
# }
# # k stores the key_name and v stores the attributes
# output "all_ranges" {
#   # This returns a list of lists: [["10.100.0.0/16"], ["10.50.0.0/16"]]
#   value = values(azurerm_virtual_network.hub_spoke_vnet)[*].address_space
# }