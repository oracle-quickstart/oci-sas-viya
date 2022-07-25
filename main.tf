terraform {
  required_version = ">= 1.0.0"

  required_providers {
    oci = {
      source  = "hashicorp/oci"
      version = "> 4.4"
    }
  }
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

data "oci_identity_regions" "regions" {
}

data "oci_identity_availability_domains" "ADs" {
  compartment_id = var.tenancy_ocid
}

locals {
  home_region = lookup(
    {
      for r in data.oci_identity_regions.regions.regions : r.key => r.name
    },
    data.oci_identity_tenancy.tenancy.home_region_key
  )
  availability_domain = lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.availability_domain - 1], "name")
}

provider "oci" {
  alias            = "home"
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = local.home_region
}

#provider "cloudinit" {
#  version = "1.0.0"
#}

data "oci_identity_tenancy" "tenancy" {
  tenancy_id = var.tenancy_ocid
}

locals {
  # Network ip ranges
  vnet_cidr_block                      = "192.168.0.0/16"
  private_subnet_cidr_block            = "192.168.0.0/24"
  public_subnet_cidr_block             = "192.168.1.0/24"
  use_existing_network                 = var.network_strategy == var.network_strategy_enum["USE_EXISTING_VCN_SUBNET"] ? true : false
  create_jump_vm_default               = true
  create_jump_vm                       = var.create_jump_vm != null ? var.create_jump_vm : local.create_jump_vm_default
  default_public_access_cidrs          = var.default_public_access_cidrs == null ? [] : var.default_public_access_cidrs
  vm_public_access_cidrs               = var.vm_public_access_cidrs == null ? local.default_public_access_cidrs : var.vm_public_access_cidrs
  cluster_endpoint_cidrs               = var.cluster_endpoint_public_access_cidrs == null ? local.default_public_access_cidrs : var.cluster_endpoint_public_access_cidrs
  cluster_endpoint_public_access_cidrs = length(local.cluster_endpoint_cidrs) == 0 ? ["0.0.0.0/32"] : local.cluster_endpoint_cidrs
}

resource "oci_core_network_security_group" "nsg" {
  compartment_id = var.compartment_ocid
  vcn_id         = local.use_existing_network ? var.vcn_id : module.vnet[0].vcn_id
  display_name   = "${var.prefix}-nsg"
  freeform_tags  = var.tags
  defined_tags   = var.defined_tags
}

resource "oci_core_security_list" "lb-subnet_security_list" {
  compartment_id = var.compartment_ocid
  display_name   = "LB Subnet"
  vcn_id         = local.use_existing_network ? var.vcn_id : module.vnet[0].vcn_id
  ingress_security_rules {
    tcp_options {
      max = 80
      min = 80
    }
    protocol = "6"
    source   = "0.0.0.0/0"
  }
  ingress_security_rules {
    tcp_options {
      max = 443
      min = 443
    }
    protocol = "6"
    source   = "0.0.0.0/0"
  }
}

module "vnet" {
  source         = "./modules/oci_vcn"
  count          = local.use_existing_network ? 0 : 1
  compartment_id = var.compartment_ocid
  name           = var.prefix
  cidr_blocks    = [local.vnet_cidr_block]
  freeform_tags  = var.tags
  defined_tags   = var.defined_tags
}

module "private-subnet" {
  source         = "./modules/oci_subnet"
  count          = local.use_existing_network ? 0 : 1
  compartment_id = var.compartment_ocid
  vcn_id         = module.vnet[count.index].vcn_id
  name           = "okeworker"
  cidr_block     = local.private_subnet_cidr_block
  private_subnet = true
  route_table_id = module.vnet[count.index].nat_route_table_id
  freeform_tags  = var.tags
  defined_tags   = var.defined_tags
}

module "public-subnet" {
  source         = "./modules/oci_subnet"
  count          = local.use_existing_network ? 0 : 1
  compartment_id = var.compartment_ocid
  vcn_id         = module.vnet[count.index].vcn_id
  name           = "public"
  cidr_block     = local.public_subnet_cidr_block
  freeform_tags  = var.tags
  defined_tags   = var.defined_tags
}


data "template_file" "jump-cloudconfig" {
  template = file("${path.module}/cloud-init/jump/cloud-config")
  vars = {
    rwx_filestore_endpoint = module.fss.mount_target_ip
    rwx_filestore_path     = module.fss.export_path
  }
}

data "template_cloudinit_config" "jump" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = data.template_file.jump-cloudconfig.rendered
  }
}

module "jump" {
  source              = "./modules/oci_vm"
  name                = "${var.prefix}-jump"
  compartment_id      = var.compartment_ocid
  availability_domain = local.availability_domain
  subnet_id           = local.use_existing_network ? var.public_subnet_id : module.public-subnet[0].subnet_id
  nsg_ids = [
    oci_core_network_security_group.nsg.id,
    module.fss.instance_nsg_id,
  ]
  create_vm        = local.create_jump_vm
  vm_admin         = "opc"
  ssh_public_key   = var.ssh_public_key
  cloud_init       = data.template_cloudinit_config.jump.rendered
  create_public_ip = var.create_jump_public_ip
  freeform_tags    = var.tags
  defined_tags     = var.defined_tags
}

resource "oci_core_network_security_group_security_rule" "ssh" {
  for_each = { for v in local.vm_public_access_cidrs : v => v }

  network_security_group_id = oci_core_network_security_group.nsg.id

  description = "Allow SSH from source"
  direction   = "INGRESS"
  protocol    = 6 # tcp
  source      = each.value
  source_type = "CIDR_BLOCK"
  stateless   = false

  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }
}


/*
## TODO: CONTAINER REGISTRY -> OCI CONTAINER REGISTRY
##              ! There does not appear to be a Terraform resource for the OCI container registry creation !
*/

module "oke" {
  source = "./modules/oci_oke"

  name               = "${var.prefix}-oke"
  compartment_id     = var.compartment_ocid
  kubernetes_version = var.kubernetes_version
  vcn_id             = local.use_existing_network ? var.vcn_id : module.vnet[0].vcn_id
  lb_subnet_ids      = [local.use_existing_network ? var.public_subnet_id : module.public-subnet[0].subnet_id]
  ssh_public_key     = var.ssh_public_key

  freeform_tags = var.tags
  defined_tags  = var.defined_tags
}

module "default_node_pool" {
  source               = "./modules/oci_oke_node_pool"
  create_node_pool     = true
  node_pool_name       = "default"
  compartment_id       = var.compartment_ocid
  oke_cluster_id       = module.oke.cluster_id
  subnet_id            = local.use_existing_network ? var.private_subnet_id : module.private-subnet[0].subnet_id
  kubernetes_version   = var.kubernetes_version
  instance_shape       = var.default_nodepool_vm_type
  flex_shape_ocpus     = var.default_flex_shape_ocpus
  os_disk_size         = var.default_nodepool_os_disk_size
  enable_auto_scaling  = var.default_nodepool_auto_scaling # TODO not implemented
  node_count           = var.default_nodepool_node_count
  max_nodes            = var.default_nodepool_max_nodes
  min_nodes            = var.default_nodepool_min_nodes
  node_taints          = var.default_nodepool_taints # TODO not implemented
  node_labels          = var.default_nodepool_labels # TODO not implemented
  availability_domains = [local.availability_domain] # TODO single AD for now
  ssh_public_key       = module.oke.public_key_openssh
  node_user_data = base64encode(join("\n", tolist([
    "#!/bin/bash",
    "curl --fail -H \"Authorization: Bearer Oracle\" -L0 http://169.254.169.254/opc/v2/instance/metadata/oke_init_script | base64 --decode >/var/run/oke-init.sh",
    "bash /var/run/oke-init.sh"
  ])))
  freeform_tags = var.tags
  defined_tags  = var.defined_tags
}

module "cas_node_pool" {
  source               = "./modules/oci_oke_node_pool"
  create_node_pool     = var.create_cas_nodepool
  node_pool_name       = "cas"
  compartment_id       = var.compartment_ocid
  oke_cluster_id       = module.oke.cluster_id
  subnet_id            = local.use_existing_network ? var.private_subnet_id : module.private-subnet[0].subnet_id
  kubernetes_version   = var.kubernetes_version
  instance_shape       = var.cas_nodepool_vm_type
  flex_shape_ocpus     = var.default_flex_shape_ocpus
  os_disk_size         = var.cas_nodepool_os_disk_size
  enable_auto_scaling  = var.cas_nodepool_auto_scaling # TODO not implemented
  node_count           = var.cas_nodepool_node_count
  max_nodes            = var.cas_nodepool_max_nodes
  min_nodes            = var.cas_nodepool_min_nodes
  node_taints          = var.cas_nodepool_taints     # TODO not implemented
  node_labels          = var.cas_nodepool_labels     # TODO not implemented
  availability_domains = [local.availability_domain] # TODO single AD for now
  ssh_public_key       = module.oke.public_key_openssh
  node_user_data = base64encode(join("\n", tolist([
    "#!/bin/bash",
    "curl --fail -H \"Authorization: Bearer Oracle\" -L0 http://169.254.169.254/opc/v2/instance/metadata/oke_init_script | base64 --decode >/var/run/oke-init.sh",
    "bash /var/run/oke-init.sh --kubelet-extra-args \"--register-with-taints workload.sas.com/class=cas:NoSchedule\""
  ])))
  freeform_tags        = var.tags
  defined_tags         = var.defined_tags
}

module "compute_node_pool" {
  source               = "./modules/oci_oke_node_pool"
  create_node_pool     = var.create_compute_nodepool
  node_pool_name       = "compute"
  compartment_id       = var.compartment_ocid
  oke_cluster_id       = module.oke.cluster_id
  subnet_id            = local.use_existing_network ? var.private_subnet_id : module.private-subnet[0].subnet_id
  kubernetes_version   = var.kubernetes_version
  instance_shape       = var.compute_nodepool_vm_type
  flex_shape_ocpus     = var.default_flex_shape_ocpus
  os_disk_size         = var.compute_nodepool_os_disk_size
  enable_auto_scaling  = var.compute_nodepool_auto_scaling # TODO not implemented
  node_count           = var.compute_nodepool_node_count
  max_nodes            = var.compute_nodepool_max_nodes
  min_nodes            = var.compute_nodepool_min_nodes
  node_taints          = var.compute_nodepool_taints # TODO not implemented
  node_labels          = var.compute_nodepool_labels # TODO not implemented
  availability_domains = [local.availability_domain] # TODO single AD for now
  ssh_public_key       = module.oke.public_key_openssh
  node_user_data = base64encode(join("\n", tolist([
    "#!/bin/bash",
    "curl --fail -H \"Authorization: Bearer Oracle\" -L0 http://169.254.169.254/opc/v2/instance/metadata/oke_init_script | base64 --decode >/var/run/oke-init.sh",
    "bash /var/run/oke-init.sh --kubelet-extra-args \"--register-with-taints workload.sas.com/class=compute:NoSchedule\""
  ])))
  freeform_tags        = var.tags
  defined_tags         = var.defined_tags
}

module "connect_node_pool" {
  source               = "./modules/oci_oke_node_pool"
  create_node_pool     = var.create_connect_nodepool
  node_pool_name       = "connect"
  compartment_id       = var.compartment_ocid
  oke_cluster_id       = module.oke.cluster_id
  subnet_id            = local.use_existing_network ? var.private_subnet_id : module.private-subnet[0].subnet_id
  kubernetes_version   = var.kubernetes_version
  instance_shape       = var.connect_nodepool_vm_type
  flex_shape_ocpus     = var.default_flex_shape_ocpus
  os_disk_size         = var.connect_nodepool_os_disk_size
  enable_auto_scaling  = var.connect_nodepool_auto_scaling # TODO not implemented
  node_count           = var.connect_nodepool_node_count
  max_nodes            = var.connect_nodepool_max_nodes
  min_nodes            = var.connect_nodepool_min_nodes
  node_taints          = var.connect_nodepool_taints # TODO not implemented
  node_labels          = var.connect_nodepool_labels # TODO not implemented
  availability_domains = [local.availability_domain] # TODO single AD for now
  ssh_public_key       = module.oke.public_key_openssh
  node_user_data = base64encode(join("\n", tolist([
    "#!/bin/bash",
    "curl --fail -H \"Authorization: Bearer Oracle\" -L0 http://169.254.169.254/opc/v2/instance/metadata/oke_init_script | base64 --decode >/var/run/oke-init.sh",
    "bash /var/run/oke-init.sh --kubelet-extra-args \"--register-with-taints workload.sas.com/class=connect:NoSchedule\""
  ])))
  freeform_tags        = var.tags
  defined_tags         = var.defined_tags
}

module "stateless_node_pool" {
  source               = "./modules/oci_oke_node_pool"
  create_node_pool     = var.create_stateless_nodepool
  node_pool_name       = "stateless"
  compartment_id       = var.compartment_ocid
  oke_cluster_id       = module.oke.cluster_id
  subnet_id            = local.use_existing_network ? var.private_subnet_id : module.private-subnet[0].subnet_id
  kubernetes_version   = var.kubernetes_version
  instance_shape       = var.stateless_nodepool_vm_type
  flex_shape_ocpus     = var.default_flex_shape_ocpus
  os_disk_size         = var.stateless_nodepool_os_disk_size
  enable_auto_scaling  = var.stateless_nodepool_auto_scaling # TODO not implemented
  node_count           = var.stateless_nodepool_node_count
  max_nodes            = var.stateless_nodepool_max_nodes
  min_nodes            = var.stateless_nodepool_min_nodes
  node_taints          = var.stateless_nodepool_taints # TODO not implemented
  node_labels          = var.stateless_nodepool_labels # TODO not implemented
  availability_domains = [local.availability_domain]   # TODO single AD for now
  ssh_public_key       = module.oke.public_key_openssh
  node_user_data = base64encode(join("\n", tolist([
    "#!/bin/bash",
    "curl --fail -H \"Authorization: Bearer Oracle\" -L0 http://169.254.169.254/opc/v2/instance/metadata/oke_init_script | base64 --decode >/var/run/oke-init.sh",
    "bash /var/run/oke-init.sh --kubelet-extra-args \"--register-with-taints workload.sas.com/class=stateless:NoSchedule\""
  ])))
  freeform_tags        = var.tags
  defined_tags         = var.defined_tags
}

module "stateful_node_pool" {
  source               = "./modules/oci_oke_node_pool"
  create_node_pool     = var.create_stateful_nodepool
  node_pool_name       = "stateful"
  compartment_id       = var.compartment_ocid
  oke_cluster_id       = module.oke.cluster_id
  subnet_id            = local.use_existing_network ? var.private_subnet_id : module.private-subnet[0].subnet_id
  kubernetes_version   = var.kubernetes_version
  instance_shape       = var.stateful_nodepool_vm_type
  flex_shape_ocpus     = var.default_flex_shape_ocpus
  os_disk_size         = var.stateful_nodepool_os_disk_size
  enable_auto_scaling  = var.stateful_nodepool_auto_scaling # TODO not implemented
  node_count           = var.stateful_nodepool_node_count
  max_nodes            = var.stateful_nodepool_max_nodes
  min_nodes            = var.stateful_nodepool_min_nodes
  node_taints          = var.stateful_nodepool_taints # TODO not implemented
  node_labels          = var.stateful_nodepool_labels # TODO not implemented
  availability_domains = [local.availability_domain]  # TODO single AD for now
  ssh_public_key       = module.oke.public_key_openssh
  node_user_data = base64encode(join("\n", tolist([
    "#!/bin/bash",
    "curl --fail -H \"Authorization: Bearer Oracle\" -L0 http://169.254.169.254/opc/v2/instance/metadata/oke_init_script | base64 --decode >/var/run/oke-init.sh",
    "bash /var/run/oke-init.sh --kubelet-extra-args \"--register-with-taints workload.sas.com/class=stateful:NoSchedule\""
  ])))
  freeform_tags        = var.tags
  defined_tags         = var.defined_tags
}

/*
## TODO: POSTGRESQL -> ???? (NOT NEEDED)
module "postgresql" {
}
*/


module "fss" {
  source = "./modules/oci_fss"

  availability_domain = local.availability_domain
  compartment_id      = var.compartment_ocid

  name        = "${var.prefix}-fss"
  path        = "/export"
  vcn_id      = local.use_existing_network ? var.vcn_id : module.vnet[0].vcn_id
  subnet_id   = local.use_existing_network ? var.private_subnet_id : module.private-subnet[0].subnet_id
  source_cidr = local.vnet_cidr_block # allow all hosts in VCN to connect to FSS mount target

  freeform_tags = var.tags
  defined_tags  = var.defined_tags
}

resource "local_file" "kubeconfig" {
  content         = module.oke.kube_config
  filename        = "${var.prefix}-oke-kubeconfig.conf"
  file_permission = "0600"
}


data "external" "git_hash" {
  program = ["files/iac_git_info.sh"]
}

data "external" "iac_tooling_version" {
  program = ["files/iac_tooling_version.sh"]
}

#resource "kubernetes_config_map" "sas_iac_buildinfo" {
#  metadata {
#    name      = "sas-iac-buildinfo"
#    namespace = "kube-system"
#  }
#
#  data = {
#    git-hash    = lookup(data.external.git_hash.result, "git-hash")
#    timestamp   = chomp(timestamp())
#    iac-tooling = var.iac_tooling
#    terraform   = <<EOT
#version: ${lookup(data.external.iac_tooling_version.result, "terraform_version")}
#revision: ${lookup(data.external.iac_tooling_version.result, "terraform_revision")}
#provider-selections: ${lookup(data.external.iac_tooling_version.result, "provider_selections")}
#outdated: ${lookup(data.external.iac_tooling_version.result, "terraform_outdated")}
#EOT
#  }
#
#  depends_on = [ module.oke ]
#}
