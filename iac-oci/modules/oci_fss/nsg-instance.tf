# network security group for instance to connect to fss

data "oci_core_private_ip" "mt-ip" {
  private_ip_id = oci_file_storage_mount_target.mt.private_ip_ids[0]
}


resource "oci_core_network_security_group" "instance-nsg" {
  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id

  display_name = "${var.name}-instance-nsg"

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_core_network_security_group_security_rule" "instance-ingress-tcp-111" {
  network_security_group_id = oci_core_network_security_group.instance-nsg.id

  direction   = "INGRESS"
  protocol    = 6 # tcp
  source      = "${data.oci_core_private_ip.mt-ip.ip_address}/32"
  source_type = "CIDR_BLOCK"
  stateless   = false

  tcp_options {
    source_port_range {
      min = 111
      max = 111
    }
  }
}

resource "oci_core_network_security_group_security_rule" "instance-ingress-tcp-2048-2050" {
  network_security_group_id = oci_core_network_security_group.instance-nsg.id

  direction   = "INGRESS"
  protocol    = 6 # tcp
  source      = "${data.oci_core_private_ip.mt-ip.ip_address}/32"
  source_type = "CIDR_BLOCK"
  stateless   = false

  tcp_options {
    source_port_range {
      min = 2048
      max = 2050
    }
  }
}

resource "oci_core_network_security_group_security_rule" "instance-ingress-udp-111" {
  network_security_group_id = oci_core_network_security_group.instance-nsg.id

  direction   = "INGRESS"
  protocol    = 17 # udp
  source      = "${data.oci_core_private_ip.mt-ip.ip_address}/32"
  source_type = "CIDR_BLOCK"
  stateless   = false

  udp_options {
    source_port_range {
      min = 111
      max = 111
    }
  }
}

resource "oci_core_network_security_group_security_rule" "instance-egress-tcp-111" {
  network_security_group_id = oci_core_network_security_group.mt-nsg.id

  direction        = "EGRESS"
  protocol         = 6 # tcp
  destination      = "${data.oci_core_private_ip.mt-ip.ip_address}/32"
  destination_type = "CIDR_BLOCK"
  stateless        = false

  tcp_options {
    destination_port_range {
      min = 111
      max = 111
    }
  }
}

resource "oci_core_network_security_group_security_rule" "instance-egress-tcp-2048-2050" {
  network_security_group_id = oci_core_network_security_group.mt-nsg.id

  direction        = "EGRESS"
  protocol         = 6 # tcp
  destination      = "${data.oci_core_private_ip.mt-ip.ip_address}/32"
  destination_type = "CIDR_BLOCK"
  stateless        = false

  tcp_options {
    destination_port_range {
      min = 2048
      max = 2050
    }
  }
}

resource "oci_core_network_security_group_security_rule" "instance-egress-udp-111" {
  network_security_group_id = oci_core_network_security_group.mt-nsg.id

  direction        = "EGRESS"
  protocol         = 17 # udp
  destination      = "${data.oci_core_private_ip.mt-ip.ip_address}/32"
  destination_type = "CIDR_BLOCK"
  stateless        = false

  udp_options {
    destination_port_range {
      min = 111
      max = 111
    }
  }
}

