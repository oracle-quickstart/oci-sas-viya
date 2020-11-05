# create oci container service (OKE)

resource "tls_private_key" "private_key" {
  count     = var.ssh_public_key == "" ? 1 : 0
  algorithm = "RSA"
}

data "tls_public_key" "public_key" {
  count           = var.ssh_public_key == "" ? 1 : 0
  private_key_pem = element(coalescelist(tls_private_key.private_key.*.private_key_pem), 0)
}

locals {
  ssh_public_key = var.ssh_public_key != "" ? file(var.ssh_public_key) : element(coalescelist(data.tls_public_key.public_key.*.public_key_openssh, [""]), 0)
}


resource "oci_containerengine_cluster" "oke" {
  compartment_id     = var.compartment_id
  kubernetes_version = var.kubernetes_version
  name               = var.name
  vcn_id             = var.vcn_id

  # TODO allow kms key
  # kms_key_id = oci_kms_key.test_key.id

  options {
    add_ons {
      is_kubernetes_dashboard_enabled = false
      is_tiller_enabled               = false
    }

    admission_controller_options {
      is_pod_security_policy_enabled = false
    }

    kubernetes_network_config {
      pods_cidr     = "10.244.0.0/16"
      services_cidr = "10.0.0.0/16"
    }

    service_lb_subnet_ids = var.lb_subnet_ids
  }
}
