
variable "tenancy_id" {}

variable "compartment_id" {
  description = "optional parent compartment_ocid, default is blank (i.e. use tenacy root)"
  default     = ""
}

variable "name" {
  description = "compartment name"
}

variable "description" {
  description = "compartment description"
}

variable "freeform_tags" {
  default = null
}

variable "defined_tags" {
  default = null
}