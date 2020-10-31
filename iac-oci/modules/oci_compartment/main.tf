# identity resources must be created in the home region
provider "oci" {}

provider oci {
  alias = "home"
}

resource "oci_identity_compartment" "compartment" {
  provider       = oci.home
  compartment_id = var.compartment_id != "" ? var.compartment_id : var.tenancy_id
  name           = var.name
  description    = var.description
  enable_delete  = false

  freeform_tags = var.freeform_tags
  defined_tags = var.defined_tags
}

