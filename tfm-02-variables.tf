variable "resource_group_name" {
  description = "(Required) Specifies the name of the Resource Group in which the Virtual Machine should exist. Changing this forces a new resource to be created."
}

variable "location" {
  description = "(Required) Specifies the Azure Region where the Virtual Machine exists. Changing this forces a new resource to be created."
}

variable "tags" {
  description = "Define tags such Environment, Cost Centre and Product"
}

variable "os" {
  description = "Define if the operating system is 'Linux' or 'Windows'"
  default     = "Windows"
}

variable "os_profile" {
  description = "(Required) A windows or Linux profile as per documentation"
}

variable "storage_image_reference" {
  description = "Define Storage Image Reference"
}

variable "storage_os_disk" {
  description = "Define the property of VM OS Disk"
  default     = null
}

variable "storage_data_disk" {
  description = "Define the property of VM Data Disk"
  default     = null
}

variable "delete_data_disks_on_termination" {
  description = "Flag indicate if delete_data_disks_on_termination is required or not"
}

variable "vm_size" {
  description = "(Required) Azure VM size name"
}

variable "availability_set_id" {
  description = "(Optional) resource id of availability set to use."
  default     = null
}

variable "availability_set_name" {
  description = "(Optional) Name of availability set to use."
  default     = ""
}

variable "windows_storage_image_reference" {
  type        = map(string)
  description = "Could containt an 'id' of a custom image or the following parameters for an Azure public 'image publisher','offer','sku', 'version'"
  default = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "Latest"
  }
}

variable "os_profile_windows_config" {
  default = null
}

variable "vnet_name" {
  description = "Name of Virtual Network where the VM will be placed"
}

variable "vnet_rg" {
  description = "Name of Resource Group of the VNet"
}

variable "subnet_name" {
  description = "Name of subnet where the VM will be placed"
}


variable "administrator_kv_name" {
  description = "Name of Key Vault in which Administrative Passwords will be stored"
}

variable "administrator_kv_rg" {
  description = "Name of the Resource Group of the Key Vault in which Administrative Passwords will be stored"
}

variable "vm_name" {
  description = "Name of Virtual Machine that will be provisioned"
}

variable "vm_private_ip" {
  description = "Optional Private IP of the VM"
}


variable "public_ip_required" {
  description = "The flag to define if Public IP is required for the VM"
}

variable "msi_rg" {
  description = "Name of the Resource Group of the User Assigned Identity"
}

variable "use_user_assigned_identity" {
  description = "The flag to define if User Assigned Identity will be used for the VM"
}
