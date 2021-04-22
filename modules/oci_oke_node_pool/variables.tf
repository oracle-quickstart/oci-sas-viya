# REQUIRED variables (must be set by caller of the module)

variable "compartment_id" {}
variable "kubernetes_version" {}

variable "create_node_pool" {
  default = false
}

variable "node_pool_name" {
  type = string
}

variable "oke_cluster_id" {
  type = string
}

variable "availability_domains" {
  type = list(string)
}

variable "subnet_id" {
  default = null
}

variable "instance_shape" {
  default = "VM.Standard2.1" # 1 OCPU, 16 GB RAM
}

variable "operating_system" {
  default = "Oracle Linux"
}

variable "operating_system_version" {
  default = "7.9"
}

variable "os_disk_size" {
  default = 50
}

variable "node_count" {
  default = 1
}

variable "enable_auto_scaling" {
  default = false
}

variable "max_nodes" {
  default = 1
}

variable "min_nodes" {
  default = 1
}

variable "node_taints" {
  type    = list
  default = []
}

variable "node_labels" {
  type    = map
  default = {}
}

variable "ssh_public_key" {
  type    = string
  default = null
}


variable "freeform_tags" {
  description = "Map of tags to be placed on the Resources"
  type        = map
}

variable "defined_tags" {
  description = "Map of tags to be placed on the Resources"
  type        = map
}
