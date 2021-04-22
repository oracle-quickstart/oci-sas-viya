variable "compartment_id" {
  type = string
}

variable "availability_domain" {
  type = string
}

variable "nsg_ids" {
  type = list
}

variable "freeform_tags" {
  description = "Map of common tags to be placed on the Resources"
  type        = map
}

variable "defined_tags" {
  description = "Map of common tags to be placed on the Resources"
  type        = map
}

variable "subnet_id" {
  type = string
}

variable "instance_shape" {
  default = "VM.Standard2.1" # 1 OCPU, 16 GB RAM
}

variable "vm_admin" {
  description = "OS Admin User for VMs of Cluster nodes"
  default     = "opc"
}

variable "ssh_public_key" {
  description = "Path to ssh public key"
  default     = ""
}

variable "operating_system" {
  default = "Oracle Linux"
}

variable "operating_system_version" {
  default = "7.9"
}

variable name {
  type = string
}

variable data_disk_count {
  default = 0
}

variable data_disk_size {
  default = 128
}

# variable data_disk_caching {
#   default = "ReadWrite"
# }

variable os_disk_size {
  default = 50
}

# variable os_disk_caching {
#   default = "ReadOnly"
# }

# variable enable_accelerated_networking {
#   default = true
# }

variable create_vm {
  default = false
}

variable cloud_init {
  default = ""
}

variable create_public_ip {
  default = false
}
