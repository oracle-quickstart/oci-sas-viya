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

