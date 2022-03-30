output "network_interface_ids" {
  depends_on = [azurerm_virtual_machine.spcc_vm]
  value      = azurerm_virtual_machine.spcc_vm.network_interface_ids
}

output "primary_network_interface_id" {
  depends_on = [azurerm_virtual_machine.spcc_vm]
  value      = azurerm_virtual_machine.spcc_vm.primary_network_interface_id
}

output "admin_username" {
  depends_on = [azurerm_virtual_machine.spcc_vm]
  value      = var.os_profile.admin_username
}

output "msi_system_principal_id" {
  value = azurerm_virtual_machine.spcc_vm.identity.0.principal_id
}

output "identity" {
  value = {
    principal_id = azurerm_virtual_machine.spcc_vm.identity[0].principal_id
    ids          = azurerm_virtual_machine.spcc_vm.identity[0].identity_ids
  }
}

output "name" {
  value = azurerm_virtual_machine.spcc_vm.name
}

output "id" {
  value = azurerm_virtual_machine.spcc_vm.id
}

output "object" {
  sensitive = true
  value     = azurerm_virtual_machine.spcc_vm.id
}
