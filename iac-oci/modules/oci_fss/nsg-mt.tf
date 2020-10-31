# network security group for the mount target

resource "oci_core_network_security_group" "mt-nsg" {
  compartment_id = var.compartment_id
  vcn_id = var.vcn_id

  display_name = "${var.name}-mt-nsg"

  freeform_tags = var.freeform_tags
  defined_tags = var.defined_tags
}

resource "oci_core_network_security_group_security_rule" "ingress-tcp-111" {
  network_security_group_id = oci_core_network_security_group.mt-nsg.id

  direction = "INGRESS"
  protocol = 6  # tcp
  source = var.source_cidr
  source_type = "CIDR_BLOCK"
  stateless = false

  tcp_options {
    destination_port_range {
        min = 111
        max = 111
    }
  }
}

resource "oci_core_network_security_group_security_rule" "ingress-tcp-2048-2050" {
  network_security_group_id = oci_core_network_security_group.mt-nsg.id

  direction = "INGRESS"
  protocol = 6  # tcp
  source = var.source_cidr
  source_type = "CIDR_BLOCK"
  stateless = false

  tcp_options {
    destination_port_range {
        min = 2048
        max = 2050
    }
  }
}

resource "oci_core_network_security_group_security_rule" "ingress-udp-111" {
  network_security_group_id = oci_core_network_security_group.mt-nsg.id

  direction = "INGRESS"
  protocol = 17  # udp
  source = var.source_cidr
  source_type = "CIDR_BLOCK"
  stateless = false

  udp_options {
    destination_port_range {
        min = 111
        max = 111
    }
  }
}

resource "oci_core_network_security_group_security_rule" "ingress-udp-2048" {
  network_security_group_id = oci_core_network_security_group.mt-nsg.id

  direction = "INGRESS"
  protocol = 17  # udp
  source = var.source_cidr
  source_type = "CIDR_BLOCK"
  stateless = false

  udp_options {
    destination_port_range {
        min = 2048
        max = 2048
    }
  }
}

resource "oci_core_network_security_group_security_rule" "egress-tcp-111" {
  network_security_group_id = oci_core_network_security_group.mt-nsg.id

  direction = "EGRESS"
  protocol = 6  # tcp
  destination = var.source_cidr
  destination_type = "CIDR_BLOCK"
  stateless = false

  tcp_options {
    source_port_range {
        min = 111
        max = 111
    }
  }
}

resource "oci_core_network_security_group_security_rule" "egress-tcp-2048-2050" {
  network_security_group_id = oci_core_network_security_group.mt-nsg.id

  direction = "EGRESS"
  protocol = 6  # tcp
  destination = var.source_cidr
  destination_type = "CIDR_BLOCK"
  stateless = false

  tcp_options {
    source_port_range {
        min = 2048
        max = 2050
    }
  }
}

resource "oci_core_network_security_group_security_rule" "egress-udp-111" {
  network_security_group_id = oci_core_network_security_group.mt-nsg.id

  direction = "EGRESS"
  protocol = 17  # udp
  destination = var.source_cidr
  destination_type = "CIDR_BLOCK"
  stateless = false

  udp_options {
    source_port_range {
        min = 111
        max = 111
    }
  }
}

