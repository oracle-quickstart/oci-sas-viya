# !NOTE! - These are only a subset of variables.tf provided for sample.
# Customize this file to add any variables from 'variables.tf' that you want 
# to change their default values. 

# ****************  REQUIRED VARIABLES  ****************
# These required variables' values MUST be provided by the User
prefix              = "<prefix-value>"
region              = "<oci-region>" # e.g., "us-ashburn-1"
tenancy_ocid        = "<tenancy_ocid>"
compartment_ocid    = "<parent_compartment_id>"
user_ocid           = "<user_ocid>"
fingerprint         = "<api_key_fingerprint>"
private_key_path    = "<private_key_path>"
availability_domain = 1
# ****************  REQUIRED VARIABLES  ****************

tags                            = { } # e.g., { "key1" = "value1", "key2" = "value2" }

# When a ssh key value is provided it will be used for all VMs or else a ssh key will be auto generated and available in outputs
ssh_public_key                  = "~/.ssh/id_rsa.pub"

# Admins access
default_public_access_cidrs             = []  # e.g., ["123.45.6.89/32"]
cluster_endpoint_public_access_cidrs    = []  # e.g., ["123.45.6.89/32"]
acr_public_access_cidrs                 = []  # e.g., ["123.45.6.89/32"]
vm_public_access_cidrs                  = []  # e.g., ["123.45.6.89/32"]
postgres_public_access_cidrs            = []  # e.g., ["123.45.6.89/32"]

# Postgres config
create_postgres                  = true # set this to "false" when using internal Crunchy Postgres
postgres_ssl_enforcement_enabled = false
postgres_administrator_password  = "mySup3rS3cretPassw0rd"

# Container Registry config
create_container_registry           = false
container_registry_sku              = "Standard"
container_registry_admin_enabled    = "false"
container_registry_geo_replica_locs = null

# OKE config
kubernetes_version                   = "v1.18.8"
default_nodepool_node_count          = 2
default_nodepool_vm_type             = "VM.Standard2.4"

# OKE Node Pools config
create_cas_nodepool       = true
cas_nodepool_node_count   = 1
cas_nodepool_min_nodes    = 1
cas_nodepool_auto_scaling = false
cas_nodepool_vm_type      = "VM.Standard2.8"

create_compute_nodepool       = true
compute_nodepool_node_count   = 1
compute_nodepool_min_nodes    = 1
compute_nodepool_auto_scaling = false
compute_nodepool_vm_type      = "VM.Standard2.8"

create_connect_nodepool       = true
connect_nodepool_node_count   = 1
connect_nodepool_min_nodes    = 1
connect_nodepool_auto_scaling = false
connect_nodepool_vm_type      = "VM.Standard2.8"

create_stateless_nodepool       = true
stateless_nodepool_node_count   = 2
stateless_nodepool_min_nodes    = 2
stateless_nodepool_auto_scaling = false
stateless_nodepool_vm_type      = "VM.Standard2.8"

create_stateful_nodepool       = true
stateful_nodepool_node_count   = 3
stateful_nodepool_min_nodes    = 3
stateful_nodepool_auto_scaling = false
stateful_nodepool_vm_type      = "VM.Standard2.8"

# Jump Box
create_jump_public_ip          = true
jump_vm_admin                  = "opc"

# Storage for SAS Viya CAS/Compute
storage_type = "standard"
# required ONLY when storage_type is "standard" to create NFS Server VM
create_nfs_public_ip  = false
nfs_vm_admin          = "opc"
nfs_raid_disk_size    = 128
