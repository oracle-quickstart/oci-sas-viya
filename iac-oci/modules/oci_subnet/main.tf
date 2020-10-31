
# create a subnet with a dedicated security list

resource "oci_core_subnet" "subnet" {
  display_name   = "${var.name}-subnet"
  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  cidr_block     = var.cidr_block
}

