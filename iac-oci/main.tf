terraform {
  required_version = ">= 0.13"
}

/*
## az2oci: CHANGE TO OCI PROVIDER
provider "azurerm" {
  version = "~>2.28.0"

  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id

  features {}
}
*/
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


/*
## az2oci: NOT NEEDED FOR OCI ?? DO WE NEED SOME INTEGRATION WITH IDCS ??
##         DO WE NEED TO DEPLOY AN AD DEPLOYMENT ON OCI FOR THIS
provider "azuread" {
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
}
*/

provider "cloudinit" {
  version = "1.0.0"
}

/*
## az2oci: SUBSCRIPTION -> TENANCY
data "azurerm_subscription" "current" {}
*/
data "oci_identity_tenancy" "tenancy" {
  tenancy_id = var.tenancy_ocid
}

/*
## az2oci: ??
data "azuread_service_principal" "sp_client" {
  application_id = var.client_id
}
*/

locals {
  # Network ip ranges
  vnet_cidr_block                      = "192.168.0.0/16"
  oke_subnet_cidr_block                = "192.168.1.0/24"
  misc_subnet_cidr_block               = "192.168.2.0/24"
  gw_subnet_cidr_block                 = "192.168.3.0/24"
  fss_subnet_cidr_block                = "192.168.0.0/24"
  create_jump_vm_default               = var.storage_type != "dev" ? true : false
  create_jump_vm                       = var.create_jump_vm != null ? var.create_jump_vm : local.create_jump_vm_default
  default_public_access_cidrs          = var.default_public_access_cidrs == null ? [] : var.default_public_access_cidrs
  vm_public_access_cidrs               = var.vm_public_access_cidrs == null ? local.default_public_access_cidrs : var.vm_public_access_cidrs
  acr_public_access_cidrs              = var.acr_public_access_cidrs == null ? local.default_public_access_cidrs : var.acr_public_access_cidrs
  cluster_endpoint_cidrs               = var.cluster_endpoint_public_access_cidrs == null ? local.default_public_access_cidrs : var.cluster_endpoint_public_access_cidrs
  cluster_endpoint_public_access_cidrs = length(local.cluster_endpoint_cidrs) == 0 ? ["0.0.0.0/32"] : local.cluster_endpoint_cidrs
  postgres_public_access_cidrs         = var.postgres_public_access_cidrs == null ? local.default_public_access_cidrs : var.postgres_public_access_cidrs
  postgres_firewall_rules              = [for addr in local.postgres_public_access_cidrs : { "name" : replace(replace(addr, "/", "_"), ".", "_"), "start_ip" : cidrhost(addr, 0), "end_ip" : cidrhost(addr, abs(pow(2, 32 - split("/", addr)[1]) - 1)) }]
}

/* 
## az2oci: RESOURCE GROUP -> OCI COMPARTMENT
module "azure_rg" {
  source = "./modules/azurerm_resource_group"

  azure_rg_name     = "${var.prefix}-rg"
  azure_rg_location = var.location
  tags              = var.tags
}
*/
module "oci_compartment" {
  source = "./modules/oci_compartment"

  providers = {
    oci      = oci
    oci.home = oci.home
  }

  tenancy_id     = var.tenancy_ocid
  compartment_id = var.compartment_ocid != null ? var.compartment_ocid : var.tenancy_ocid

  name        = "${var.prefix}-comp"
  description = "SAS Viya 4 Deployment Compartment"

  freeform_tags = var.tags
  defined_tags  = var.defined_tags
}


/*
## az2oci: NETWORK SECURITY GROUP -> OCI NETWORK SECURITY GROUP
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.prefix}-nsg"
  location            = var.location
  resource_group_name = module.azure_rg.name

  tags = var.tags
}
*/
resource "oci_core_network_security_group" "nsg" {
  compartment_id = module.oci_compartment.compartment_id
  vcn_id         = module.vnet.vcn_id
  display_name   = "${var.prefix}-nsg"
  freeform_tags  = var.tags
  defined_tags   = var.defined_tags
}

/*
##  az2oci: VIRTUAL NETWORK -> OCI VCN
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-vnet"
  location            = var.location
  resource_group_name = module.azure_rg.name
  address_space       = [local.vnet_cidr_block]
  tags                = var.tags
}
*/
module vnet {
  source         = "./modules/oci_vcn"
  compartment_id = module.oci_compartment.compartment_id
  name           = var.prefix
  cidr_block     = local.vnet_cidr_block
  freeform_tags  = var.tags
  defined_tags   = var.defined_tags
}


/*
## az2oci: SUBNET -> OCI SUBNET
module "gw-subnet" {
  source            = "./modules/azure_subnet"
  name              = "${var.prefix}-gw"
  azure_rg_name     = module.azure_rg.name
  azure_rg_location = var.location
  nsg               = azurerm_network_security_group.nsg
  address_prefixes  = [local.gw_subnet_cidr_block]
  vnet_name         = azurerm_virtual_network.vnet.name
  service_endpoints = var.create_postgres ? ["Microsoft.Sql"] : []
  tags              = var.tags
}
*/
module "gw-subnet" {
  source         = "./modules/oci_subnet"
  compartment_id = module.oci_compartment.compartment_id
  vcn_id         = module.vnet.vcn_id
  name           = "gw"
  cidr_block     = local.gw_subnet_cidr_block
  freeform_tags  = var.tags
  defined_tags   = var.defined_tags
}

/*
module "aks-subnet" {
  source            = "./modules/azure_subnet"
  name              = "${var.prefix}-aks"
  azure_rg_name     = module.azure_rg.name
  azure_rg_location = var.location
  address_prefixes  = [local.aks_subnet_cidr_block]
  vnet_name         = azurerm_virtual_network.vnet.name
  service_endpoints = var.create_postgres ? ["Microsoft.Sql"] : []
  tags              = var.tags
}
*/
module "oke-lb-subnet" {
  source         = "./modules/oci_subnet"
  compartment_id = module.oci_compartment.compartment_id
  vcn_id         = module.vnet.vcn_id
  name           = "okelb"
  cidr_block     = cidrsubnet(local.oke_subnet_cidr_block, 2, 1)
  freeform_tags  = var.tags
  defined_tags   = var.defined_tags
}

module "oke-worker-subnet" {
  source         = "./modules/oci_subnet"
  compartment_id = module.oci_compartment.compartment_id
  vcn_id         = module.vnet.vcn_id
  name           = "okeworker"
  cidr_block     = cidrsubnet(local.oke_subnet_cidr_block, 2, 2)
  private_subnet = true
  route_table_id = module.vnet.nat_route_table_id
  freeform_tags  = var.tags
  defined_tags   = var.defined_tags
}

/*
module "misc-subnet" {
  source            = "./modules/azure_subnet"
  name              = "${var.prefix}-misc"
  azure_rg_name     = module.azure_rg.name
  azure_rg_location = var.location
  nsg               = azurerm_network_security_group.nsg
  address_prefixes  = [local.misc_subnet_cidr_block]
  vnet_name         = azurerm_virtual_network.vnet.name
  service_endpoints = var.create_postgres ? ["Microsoft.Sql"] : []
  tags              = var.tags
}
*/
module "misc-subnet" {
  source         = "./modules/oci_subnet"
  compartment_id = module.oci_compartment.compartment_id
  vcn_id         = module.vnet.vcn_id
  name           = "misc"
  cidr_block     = local.misc_subnet_cidr_block
  freeform_tags  = var.tags
  defined_tags   = var.defined_tags
}


data "template_file" "jump-cloudconfig" {
  template = file("${path.module}/cloud-init/jump/cloud-config")
  vars = {
    rwx_filestore_endpoint = var.storage_type == "dev" ? "" : module.fss.mount_target_ip
    rwx_filestore_path     = var.storage_type == "dev" ? "" : module.fss.export_path
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


/*
module "jump" {
  source            = "./modules/azurerm_vm"
  name              = "${var.prefix}-jump"
  azure_rg_name     = module.azure_rg.name
  azure_rg_location = var.location
  vnet_subnet_id    = module.misc-subnet.subnet_id
  azure_nsg_id      = azurerm_network_security_group.nsg.id
  tags              = var.tags
  create_vm         = local.create_jump_vm
  vm_admin          = var.jump_vm_admin
  ssh_public_key    = var.ssh_public_key
  # ssh_private_key   = var.ssh_private_key
  cloud_init       = var.storage_type == "dev" ? null : data.template_cloudinit_config.jump.rendered
  create_public_ip = var.create_jump_public_ip
}
*/
module "jump" {
  source              = "./modules/oci_vm"
  name                = "${var.prefix}-jump"
  compartment_id      = module.oci_compartment.compartment_id
  availability_domain = local.availability_domain
  subnet_id           = module.misc-subnet.subnet_id
  nsg_ids = [
    oci_core_network_security_group.nsg.id,
    module.fss.instance_nsg_id,
  ]
  create_vm        = local.create_jump_vm
  vm_admin         = "opc"
  ssh_public_key   = var.ssh_public_key
  cloud_init       = var.storage_type == "dev" ? null : data.template_cloudinit_config.jump.rendered
  create_public_ip = var.create_jump_public_ip
  freeform_tags    = var.tags
  defined_tags     = var.defined_tags
}

/*
## az2oci: SECURITY RULE -> NETWORK SECURITY GROUP SECURITY RULE
resource "azurerm_network_security_rule" "ssh" {
  name                        = "${var.prefix}-ssh"
  description                 = "Allow SSH from source"
  count                       = (var.create_jump_public_ip && local.create_jump_vm && length(local.vm_public_access_cidrs) != 0) ? 1 : 0
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefixes     = local.vm_public_access_cidrs
  destination_address_prefix  = "*"
  resource_group_name         = module.azure_rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}
*/
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
data "template_file" "nfs-cloudconfig" {
  template = file("${path.module}/cloud-init/nfs/cloud-config")
  vars = {
    base_cidr_block = local.vnet_cidr_block
  }
}

data "template_cloudinit_config" "nfs" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = data.template_file.nfs-cloudconfig.rendered
  }
}

/*
## TODO az2oci: NOT REQUIED, USING OCI FSS
module "nfs" {
  source    = "./modules/azurerm_vm"
  create_vm = var.storage_type == "standard" ? true : false

  name              = "${var.prefix}-nfs"
  azure_rg_name     = module.azure_rg.name
  azure_rg_location = var.location
  vnet_subnet_id    = module.misc-subnet.subnet_id
  azure_nsg_id      = azurerm_network_security_group.nsg.id
  tags              = var.tags
  data_disk_count   = 4
  data_disk_size    = var.nfs_raid_disk_size
  vm_admin          = var.nfs_vm_admin
  ssh_public_key    = var.ssh_public_key
  # ssh_private_key   = var.ssh_private_key
  cloud_init       = data.template_cloudinit_config.nfs.rendered
  create_public_ip = var.create_nfs_public_ip
}
*/


/*
## TODO az2oci: CONTAINER REGISTRY -> OCI CONTAINER REGISTRY
##              ! There does not appear to be a Terraform resource for the OCI container registry creation !
##
module "acr" {
  source                              = "./modules/azurerm_container_registry"
  create_container_registry           = var.create_container_registry
  container_registry_name             = join("", regexall("[a-zA-Z0-9]+", "${var.prefix}acr")) # alpha numeric characters only are allowed
  container_registry_rg               = module.azure_rg.name
  container_registry_location         = var.location
  container_registry_sku              = var.container_registry_sku
  container_registry_admin_enabled    = var.container_registry_admin_enabled
  container_registry_geo_replica_locs = var.container_registry_geo_replica_locs
  container_registry_sp_role          = data.azuread_service_principal.sp_client.id
}

resource "azurerm_network_security_rule" "acr" {
  name                        = "SAS-ACR"
  description                 = "Allow ACR from source"
  count                       = (length(local.acr_public_access_cidrs) != 0 && var.create_container_registry) ? 1 : 0
  priority                    = 180
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "5000"
  source_address_prefixes     = local.acr_public_access_cidrs
  destination_address_prefix  = "*"
  resource_group_name         = module.azure_rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}
*/

/*
## az2oci: AKS -> OKE
module "aks" {
  source = "./modules/azure_aks"

  aks_cluster_name = "${var.prefix}-aks"
  aks_cluster_rg   = module.azure_rg.name
  #aks_cluster_dns_prefix - must contain between 2 and 45 characters. The name can contain only letters, numbers, and hyphens. The name must start with a letter and must end with an alphanumeric character
  aks_cluster_dns_prefix                   = "${var.prefix}-aks"
  aks_cluster_location                     = var.location
  aks_cluster_node_auto_scaling            = var.default_nodepool_auto_scaling
  aks_cluster_max_nodes                    = var.default_nodepool_max_nodes
  aks_cluster_min_nodes                    = var.default_nodepool_min_nodes
  aks_cluster_node_count                   = var.default_nodepool_node_count
  aks_cluster_max_pods                     = var.default_nodepool_max_pods
  aks_cluster_os_disk_size                 = var.default_nodepool_os_disk_size
  aks_cluster_node_vm_size                 = var.default_nodepool_vm_type
  aks_cluster_node_admin                   = var.node_vm_admin
  aks_cluster_ssh_public_key               = var.ssh_public_key
  aks_vnet_subnet_id                       = module.aks-subnet.subnet_id
  aks_client_id                            = var.client_id
  aks_client_secret                        = var.client_secret
  kubernetes_version                       = var.kubernetes_version
  aks_cluster_endpoint_public_access_cidrs = local.cluster_endpoint_public_access_cidrs
  aks_availability_zones                   = var.default_nodepool_availability_zones
  aks_cluster_tags                         = var.tags
}
*/
module "oke" {
  source = "./modules/oci_oke"

  name               = "${var.prefix}-oke"
  compartment_id     = module.oci_compartment.compartment_id
  kubernetes_version = var.kubernetes_version
  vcn_id             = module.vnet.vcn_id
  lb_subnet_ids      = [module.oke-lb-subnet.subnet_id]

  freeform_tags = var.tags
  defined_tags  = var.defined_tags
}

/*
## TODO az2oci: ????
data "azurerm_public_ip" "aks_public_ip" {
  name                = split("/", module.aks.cluster_slb_ip_id)[8]
  resource_group_name = "MC_${module.azure_rg.name}_${module.aks.name}_${module.azure_rg.location}"

  depends_on = [module.aks, module.cas_node_pool, module.compute_node_pool, module.connect_node_pool, module.stateless_node_pool, module.stateful_node_pool]
}
*/

/*
## az2oci: NODE POOL -> OCI OKE NODE POOL 
module "cas_node_pool" {
  source              = "./modules/aks_node_pool"
  create_node_pool    = var.create_cas_nodepool
  node_pool_name      = "cas" # <- characters a-z0-9 only with max length of 12
  aks_cluster_id      = module.aks.cluster_id
  vnet_subnet_id      = module.aks-subnet.subnet_id
  machine_type        = var.cas_nodepool_vm_type
  os_disk_size        = var.cas_nodepool_os_disk_size
  enable_auto_scaling = var.cas_nodepool_auto_scaling
  node_count          = var.cas_nodepool_node_count
  max_nodes           = var.cas_nodepool_max_nodes
  min_nodes           = var.cas_nodepool_min_nodes
  node_taints         = var.cas_nodepool_taints
  node_labels         = var.cas_nodepool_labels
  availability_zones  = var.cas_nodepool_availability_zones
  tags                = var.tags
}
*/
module "cas_node_pool" {
  source               = "./modules/oci_oke_node_pool"
  create_node_pool     = var.create_cas_nodepool
  node_pool_name       = "cas"
  compartment_id       = module.oci_compartment.compartment_id
  oke_cluster_id       = module.oke.cluster_id
  subnet_id            = module.oke-worker-subnet.subnet_id
  kubernetes_version   = var.kubernetes_version
  instance_shape       = var.cas_nodepool_vm_type
  os_disk_size         = var.cas_nodepool_os_disk_size
  enable_auto_scaling  = var.cas_nodepool_auto_scaling # TODO not implemented
  node_count           = var.cas_nodepool_node_count
  max_nodes            = var.cas_nodepool_max_nodes
  min_nodes            = var.cas_nodepool_min_nodes
  node_taints          = var.cas_nodepool_taints     # TODO not implemented
  node_labels          = var.cas_nodepool_labels     # TODO not implemented
  availability_domains = [local.availability_domain] # TODO single AD for now
  ssh_public_key       = module.oke.public_key_openssh
  freeform_tags        = var.tags
  defined_tags         = var.defined_tags
}

/*
## az2oci: NODE POOL -> OCI OKE NODE POOL 
module "compute_node_pool" {
  source              = "./modules/aks_node_pool"
  create_node_pool    = var.create_compute_nodepool
  node_pool_name      = "compute" # <- characters a-z0-9 only with max length of 12
  aks_cluster_id      = module.aks.cluster_id
  vnet_subnet_id      = module.aks-subnet.subnet_id
  machine_type        = var.compute_nodepool_vm_type
  os_disk_size        = var.compute_nodepool_os_disk_size
  enable_auto_scaling = var.compute_nodepool_auto_scaling
  node_count          = var.compute_nodepool_node_count
  max_nodes           = var.compute_nodepool_max_nodes
  min_nodes           = var.compute_nodepool_min_nodes
  node_taints         = var.compute_nodepool_taints
  node_labels         = var.compute_nodepool_labels
  availability_zones  = var.compute_nodepool_availability_zones
  tags                = var.tags
}
*/
module "compute_node_pool" {
  source               = "./modules/oci_oke_node_pool"
  create_node_pool     = var.create_compute_nodepool
  node_pool_name       = "compute"
  compartment_id       = module.oci_compartment.compartment_id
  oke_cluster_id       = module.oke.cluster_id
  subnet_id            = module.oke-worker-subnet.subnet_id
  kubernetes_version   = var.kubernetes_version
  instance_shape       = var.compute_nodepool_vm_type
  os_disk_size         = var.compute_nodepool_os_disk_size
  enable_auto_scaling  = var.compute_nodepool_auto_scaling # TODO not implemented
  node_count           = var.compute_nodepool_node_count
  max_nodes            = var.compute_nodepool_max_nodes
  min_nodes            = var.compute_nodepool_min_nodes
  node_taints          = var.compute_nodepool_taints # TODO not implemented
  node_labels          = var.compute_nodepool_labels # TODO not implemented
  availability_domains = [local.availability_domain] # TODO single AD for now
  ssh_public_key       = module.oke.public_key_openssh
  freeform_tags        = var.tags
  defined_tags         = var.defined_tags
}

/*
## az2oci: NODE POOL -> OCI OKE NODE POOL 
module "connect_node_pool" {
  source              = "./modules/aks_node_pool"
  create_node_pool    = var.create_connect_nodepool
  node_pool_name      = "connect" # <- characters a-z0-9 only with max length of 12
  aks_cluster_id      = module.aks.cluster_id
  vnet_subnet_id      = module.aks-subnet.subnet_id
  machine_type        = var.connect_nodepool_vm_type
  os_disk_size        = var.connect_nodepool_os_disk_size
  enable_auto_scaling = var.connect_nodepool_auto_scaling
  node_count          = var.connect_nodepool_node_count
  max_nodes           = var.connect_nodepool_max_nodes
  min_nodes           = var.connect_nodepool_min_nodes
  node_taints         = var.connect_nodepool_taints
  node_labels         = var.connect_nodepool_labels
  availability_zones  = var.connect_nodepool_availability_zones
  tags                = var.tags
}
*/
module "connect_node_pool" {
  source               = "./modules/oci_oke_node_pool"
  create_node_pool     = var.create_connect_nodepool
  node_pool_name       = "connect"
  compartment_id       = module.oci_compartment.compartment_id
  oke_cluster_id       = module.oke.cluster_id
  subnet_id            = module.oke-worker-subnet.subnet_id
  kubernetes_version   = var.kubernetes_version
  instance_shape       = var.connect_nodepool_vm_type
  os_disk_size         = var.connect_nodepool_os_disk_size
  enable_auto_scaling  = var.connect_nodepool_auto_scaling # TODO not implemented
  node_count           = var.connect_nodepool_node_count
  max_nodes            = var.connect_nodepool_max_nodes
  min_nodes            = var.connect_nodepool_min_nodes
  node_taints          = var.connect_nodepool_taints # TODO not implemented
  node_labels          = var.connect_nodepool_labels # TODO not implemented
  availability_domains = [local.availability_domain] # TODO single AD for now
  ssh_public_key       = module.oke.public_key_openssh
  freeform_tags        = var.tags
  defined_tags         = var.defined_tags
}

/*
## az2oci: NODE POOL -> OCI OKE NODE POOL 
module "stateless_node_pool" {
  source              = "./modules/aks_node_pool"
  create_node_pool    = var.create_stateless_nodepool
  node_pool_name      = "stateless" # <- characters a-z0-9 only with max length of 12
  aks_cluster_id      = module.aks.cluster_id
  vnet_subnet_id      = module.aks-subnet.subnet_id
  machine_type        = var.stateless_nodepool_vm_type
  os_disk_size        = var.stateless_nodepool_os_disk_size
  enable_auto_scaling = var.stateless_nodepool_auto_scaling
  node_count          = var.stateless_nodepool_node_count
  max_nodes           = var.stateless_nodepool_max_nodes
  min_nodes           = var.stateless_nodepool_min_nodes
  node_taints         = var.stateless_nodepool_taints
  node_labels         = var.stateless_nodepool_labels
  availability_zones  = var.stateless_nodepool_availability_zones
  tags                = var.tags
}
*/
module "stateless_node_pool" {
  source               = "./modules/oci_oke_node_pool"
  create_node_pool     = var.create_stateless_nodepool
  node_pool_name       = "stateless"
  compartment_id       = module.oci_compartment.compartment_id
  oke_cluster_id       = module.oke.cluster_id
  subnet_id            = module.oke-worker-subnet.subnet_id
  kubernetes_version   = var.kubernetes_version
  instance_shape       = var.stateless_nodepool_vm_type
  os_disk_size         = var.stateless_nodepool_os_disk_size
  enable_auto_scaling  = var.stateless_nodepool_auto_scaling # TODO not implemented
  node_count           = var.stateless_nodepool_node_count
  max_nodes            = var.stateless_nodepool_max_nodes
  min_nodes            = var.stateless_nodepool_min_nodes
  node_taints          = var.stateless_nodepool_taints # TODO not implemented
  node_labels          = var.stateless_nodepool_labels # TODO not implemented
  availability_domains = [local.availability_domain]   # TODO single AD for now
  ssh_public_key       = module.oke.public_key_openssh
  freeform_tags        = var.tags
  defined_tags         = var.defined_tags
}

/*
## az2oci: NODE POOL -> OCI OKE NODE POOL 
module "stateful_node_pool" {
  source              = "./modules/aks_node_pool"
  create_node_pool    = var.create_stateful_nodepool
  node_pool_name      = "stateful" # <- characters a-z0-9 only with max length of 12
  aks_cluster_id      = module.aks.cluster_id
  vnet_subnet_id      = module.aks-subnet.subnet_id
  machine_type        = var.stateful_nodepool_vm_type
  os_disk_size        = var.stateful_nodepool_os_disk_size
  enable_auto_scaling = var.stateful_nodepool_auto_scaling
  node_count          = var.stateful_nodepool_node_count
  max_nodes           = var.stateful_nodepool_max_nodes
  min_nodes           = var.stateful_nodepool_min_nodes
  node_taints         = var.stateful_nodepool_taints
  node_labels         = var.stateful_nodepool_labels
  availability_zones  = var.stateful_nodepool_availability_zones
  tags                = var.tags
}
*/
module "stateful_node_pool" {
  source               = "./modules/oci_oke_node_pool"
  create_node_pool     = var.create_stateful_nodepool
  node_pool_name       = "stateful"
  compartment_id       = module.oci_compartment.compartment_id
  oke_cluster_id       = module.oke.cluster_id
  subnet_id            = module.oke-worker-subnet.subnet_id
  kubernetes_version   = var.kubernetes_version
  instance_shape       = var.stateful_nodepool_vm_type
  os_disk_size         = var.stateful_nodepool_os_disk_size
  enable_auto_scaling  = var.stateful_nodepool_auto_scaling # TODO not implemented
  node_count           = var.stateful_nodepool_node_count
  max_nodes            = var.stateful_nodepool_max_nodes
  min_nodes            = var.stateful_nodepool_min_nodes
  node_taints          = var.stateful_nodepool_taints # TODO not implemented
  node_labels          = var.stateful_nodepool_labels # TODO not implemented
  availability_domains = [local.availability_domain]  # TODO single AD for now
  ssh_public_key       = module.oke.public_key_openssh
  freeform_tags        = var.tags
  defined_tags         = var.defined_tags
}

/*
## TODO az2oci: POSTGRESQL -> ???? (NOT NEEDED) 
module "postgresql" {
  source          = "./modules/postgresql"
  create_postgres = var.create_postgres

  resource_group_name             = module.azure_rg.name
  postgres_administrator_login    = var.postgres_administrator_login
  postgres_administrator_password = var.postgres_administrator_password
  location                        = var.location
  # "server_name" match regex "^[0-9a-z][-0-9a-z]{1,61}[0-9a-z]$"
  # "server_name" can contain only lowercase letters, numbers, and '-', but can't start or end with '-'. And must be at least 3 characters and at most 63 characters
  server_name                           = lower("${var.prefix}-pgsql")
  postgres_sku_name                     = var.postgres_sku_name
  postgres_storage_mb                   = var.postgres_storage_mb
  postgres_backup_retention_days        = var.postgres_backup_retention_days
  postgres_geo_redundant_backup_enabled = var.postgres_geo_redundant_backup_enabled
  tags                                  = var.tags
  postgres_server_version               = var.postgres_server_version
  postgres_ssl_enforcement_enabled      = var.postgres_ssl_enforcement_enabled
  postgres_db_names                     = var.postgres_db_names
  postgres_db_charset                   = var.postgres_db_charset
  postgres_db_collation                 = var.postgres_db_collation
  postgres_firewall_rule_prefix         = "${var.prefix}-postgres-firewall-"
  postgres_firewall_rules               = local.postgres_firewall_rules
  postgres_vnet_rule_prefix             = "${var.prefix}-postgresql-vnet-rule-"
  postgres_vnet_rules                   = [{ name = module.misc-subnet.subnet_name, subnet_id = module.misc-subnet.subnet_id }, { name = module.aks-subnet.subnet_name, subnet_id = module.aks-subnet.subnet_id }]
}
*/

/*
## az2oci: NETAPP -> FSS
module "netapp" {
  source        = "./modules/azurerm_netapp"
  create_netapp = var.storage_type == "ha" ? true : false

  prefix                = var.prefix
  resource_group_name   = module.azure_rg.name
  location              = module.azure_rg.location
  vnet_name             = azurerm_virtual_network.vnet.name
  subnet_address_prefix = [local.netapp_subnet_cidr_block]
  service_level         = var.netapp_service_level
  size_in_tb            = var.netapp_size_in_tb
  protocols             = var.netapp_protocols
  volume_path           = "${var.prefix}-${var.netapp_volume_path}"
}
*/
module "fss-subnet" {
  source         = "./modules/oci_subnet"
  compartment_id = module.oci_compartment.compartment_id
  vcn_id         = module.vnet.vcn_id
  name           = "fss"
  cidr_block     = local.fss_subnet_cidr_block
  freeform_tags  = var.tags
  defined_tags   = var.defined_tags
}

module "fss" {
  source = "./modules/oci_fss"

  availability_domain = local.availability_domain
  compartment_id      = module.oci_compartment.compartment_id

  name        = "${var.prefix}-fss"
  path        = "/export"
  vcn_id      = module.vnet.vcn_id
  subnet_id   = module.fss-subnet.subnet_id
  source_cidr = local.vnet_cidr_block # allow all hosts in VCN to connect to FSS mount target

  freeform_tags = var.tags
  defined_tags  = var.defined_tags
}

/*
resource "local_file" "kubeconfig" {
  content  = module.aks.kube_config
  filename = "${var.prefix}-aks-kubeconfig.conf"
}
*/
resource "local_file" "kubeconfig" {
  content  = module.oke.kube_config
  filename = "${var.prefix}-oke-kubeconfig.conf"
}
