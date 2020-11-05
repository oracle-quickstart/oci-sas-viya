variable name {
  description = "Name"
}

variable "freeform_tags" {
  description = "Map of common tags to be placed on the Resources"
  type        = map
}

variable "defined_tags" {
  description = "Map of common tags to be placed on the Resources"
  type        = map
}

variable "compartment_id" {
  description = "Existing compartment id"
}

variable "vcn_id" {
  description = "Existing VCN id"
}

variable "cidr_block" {
  type        = string
  description = "Desired subnet cidr"
}

variable "route_table_id" {
  type        = string
  description = "Optional route table id, uses the VCNs default route table if not set"
  default     = null
}

variable "private_subnet" {
  type        = bool
  description = "Prohibit Public IPs in subnet"
  default     = false
}