# Get Subnet ID
data "azurerm_subnet" "spcc_subnet" {
  name                 = var.subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = var.vnet_rg
}

# output "subnet_id" {
#   value = data.azurerm_subnet.spcc_subnet.id
# }

# Get Key Vault ID
data "azurerm_key_vault" "spcc_administrator_kv" {
  name                = var.administrator_kv_name
  resource_group_name = var.administrator_kv_rg
}

# output "keyvault_id" {
#   value = data.azurerm_key_vault.spcc_administrator_kv.id
# }

# Get Availability Set ID
data "azurerm_availability_set" "spcc_availability_set" {
  count               = var.availability_set_name == "" ? 0 : 1
  name                = var.availability_set_name
  resource_group_name = var.resource_group_name
}

# output "availability_set_id" {
#   value = var.availability_set_name == "" ? null : data.azurerm_availability_set.spcc_availability_set[0].id
# }

# Create a User Assigned Identity (USId) if use_user_assigned_identity == "true"
resource "azurerm_user_assigned_identity" "spcc_usid" {
  count               = var.use_user_assigned_identity == "true" ? 1 : 0
  resource_group_name = var.msi_rg
  location            = var.location

  name = "${var.vm_name}-msi"

}

# Create public IPs
resource "azurerm_public_ip" "spcc_vm_public_ip" {

  count = var.public_ip_required ? 1 : 0

  name                = "${var.vm_name}-publicip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Create Virtual Network Adapter
resource "azurerm_network_interface" "spcc_nic" {
  name                = "${var.vm_name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "${var.vm_name}-ipconf"
    subnet_id                     = data.azurerm_subnet.spcc_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.vm_private_ip
    public_ip_address_id          = var.public_ip_required ? azurerm_public_ip.spcc_vm_public_ip[0].id : null
  }
}

# Generate 24-character random password for Local Administrator
resource "random_password" "spcc_random_password" {
  length           = 24
  min_upper        = 2
  min_lower        = 2
  min_special      = 2
  number           = true
  special          = true
  override_special = "!@#$%&"
}

# Insert generated password into the Key Vault
resource "azurerm_key_vault_secret" "spcc_admin_password" {
  name         = format("%s-administrator-password", var.vm_name)
  value        = random_password.spcc_random_password.result
  key_vault_id = data.azurerm_key_vault.spcc_administrator_kv.id

  lifecycle {
    ignore_changes = [
      value
    ]
  }
}


########################

# Generate random text for a unique storage account name
resource "random_id" "spcc_sa_id" {

  byte_length = 8
}



# Create storage account for boot diagnostics
resource "azurerm_storage_account" "spcc_boot_diagnostics_sa" {
  name                     = "bootdiag${random_id.spcc_sa_id.hex}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Hardening the Storage Account
  enable_https_traffic_only = "true"
  allow_blob_public_access  = "false"
  min_tls_version           = "TLS1_2"

  tags = var.tags
}


resource "azurerm_virtual_machine" "spcc_vm" {
  name                  = var.vm_name
  resource_group_name   = var.resource_group_name
  location              = var.location
  vm_size               = var.vm_size
  tags                  = var.tags
  network_interface_ids = [azurerm_network_interface.spcc_nic.id]

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = var.delete_data_disks_on_termination

  primary_network_interface_id = azurerm_network_interface.spcc_nic.id

  os_profile {
    computer_name  = var.os_profile.computer_name
    admin_username = var.os_profile.admin_username
    admin_password = random_password.spcc_random_password.result
  }

  dynamic "storage_image_reference" {
    for_each = lookup(var.storage_image_reference, "id", null) == null ? [1] : []

    content {
      publisher = var.storage_image_reference.publisher
      offer     = var.storage_image_reference.offer
      sku       = var.storage_image_reference.sku
      version   = var.storage_image_reference.version
    }
  }


  storage_os_disk {
    name                      = "${var.os_profile.computer_name}_osdisk1"
    managed_disk_type         = var.storage_os_disk.managed_disk_type
    caching                   = var.storage_os_disk.caching
    create_option             = var.storage_os_disk.create_option
    disk_size_gb              = var.storage_os_disk.disk_size_gb
    write_accelerator_enabled = lookup(var.storage_os_disk, "write_accelerator_enabled", null)
  }


  dynamic "storage_data_disk" {
    for_each = var.storage_data_disk

    content {
      name                      = "${var.os_profile.computer_name}_datadisk${lookup(storage_data_disk.value, "id", null)}"
      caching                   = lookup(storage_data_disk.value, "caching", null)
      create_option             = lookup(storage_data_disk.value, "create_option", null)
      disk_size_gb              = lookup(storage_data_disk.value, "disk_size_gb", null)
      lun                       = lookup(storage_data_disk.value, "lun", null)
      write_accelerator_enabled = lookup(storage_data_disk.value, "write_accelerator_enabled", null)
      managed_disk_type         = lookup(storage_data_disk.value, "managed_disk_type", null)
      managed_disk_id           = lookup(storage_data_disk.value, "managed_disk_id", null)
    }
  }

  boot_diagnostics {
    enabled     = "true"
    storage_uri = azurerm_storage_account.spcc_boot_diagnostics_sa.primary_blob_endpoint
  }


  dynamic "os_profile_windows_config" {

    for_each = lower(var.os) == "windows" ? [1] : []

    content {
      provision_vm_agent        = lookup(var.os_profile, "provision_vm_agent", null)
      enable_automatic_upgrades = lookup(var.os_profile, "enable_automatic_upgrades", null)
      timezone                  = lookup(var.os_profile, "timezone", null)
    }
  }

  identity {
    type         = var.use_user_assigned_identity == "false" ? "SystemAssigned" : "UserAssigned"
    identity_ids = var.use_user_assigned_identity == "false" ? null : [azurerm_user_assigned_identity.spcc_usid[0].id]

  }

  license_type = lookup(var.os_profile, "license_type", null)

  availability_set_id = var.availability_set_name == "" ? null : data.azurerm_availability_set.spcc_availability_set[0].id

}

# Add VM to the VM Backup Facility in Azure Recovery Vault
# resource "azurerm_backup_protected_vm" "backup_protected_virtual_machine" {
#   depends_on = [azurerm_virtual_machine.spcc_vm]
#   resource_group_name = var.recovery_vault_rg
#   recovery_vault_name = var.recovery_vault_name
#   source_vm_id        = azurerm_virtual_machine.spcc_vm.id
#   backup_policy_id    = var.backup_policy_id
# }