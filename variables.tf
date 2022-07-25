
variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}

variable "compartment_ocid" {
  description = "Compartment resources will be placed in."
}

variable "iac_tooling" {
  description = "Value used to identify the tooling used to generate this providers infrastructure."
  type        = string
  default     = "terraform"
}


variable "prefix" {
  description = "A prefix used in the name for all the OCI resources created by this script. The prefix string must start with lowercase letter and contain only alphanumeric characters and hyphen or dash(-), but can not start or end with '-'."
  type        = string
  default     = "viya"
  validation {
    condition     = can(regex("^[a-z][-0-9a-zA-Z]*[0-9a-zA-Z]$", var.prefix)) && length(var.prefix) > 2 && length(var.prefix) < 21
    error_message = "ERROR: Value of 'prefix'\n * must contain at least one alphanumeric character and at most 20 characters\n * can only contain letters, numbers, and hyphen or dash(-), but can't start or end with '-'."
  }
}

variable "region" {
  description = "The OCI Region to provision all resources in this script"
  default     = "us-ashburn-1"
}

variable "availability_domain" {
  description = "The OCI regional Availability Domain to provision all resources in this script. 1, 2, or 3"
  default     = 1
}

variable "network_strategy_enum" {
  type = map
  default = {
    CREATE_NEW_VCN_SUBNET   = "Create New VCN and Subnet"
    USE_EXISTING_VCN_SUBNET = "Use Existing VCN and Subnet"
  }
}

variable "network_strategy" {
  #default = "Use Existing VCN and Subnet"
  default = "Create New VCN and Subnet"
}

#
# If deployiing into an existing network set 4 vars below
#
variable "vcn_id" {
  default = ""
}

variable "public_subnet_id" {
  default = ""
}

variable "private_subnet_id" {
  default = ""
}

variable "nat_gateway_ip" {
  default = ""
}

#########

variable "ssh_public_key" {
  type = string
}

variable "node_vm_admin" {
  description = "OS Admin User for VMs of OKE Cluster nodes"
  default     = "opc"
}

variable "default_nodepool_vm_type" {
  default = "VM.Standard.E4.Flex" # default 8 ocpu
}

variable "default_flex_shape_ocpus" {
  default = "8"
}

variable "kubernetes_version" {
  description = "The OKE cluster K8s version"
  default     = "v1.22.5"
}

variable "default_public_access_cidrs" {
  description = "List of CIDRs to access created resources"
  type        = list(string)
  default     = null
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDRs to access Kubernetes cluster"
  type        = list(string)
  default     = null
}

variable "vm_public_access_cidrs" {
  description = "List of CIDRs to access jump or nfs VM"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "default_nodepool_auto_scaling" {
  description = "Autoscale nodes in the AKS cluster default nodepool"
  default     = true
}
variable "default_nodepool_max_nodes" {
  description = "(Required, when default_nodepool_auto_scaling=true) The maximum number of nodes which should exist in this Node Pool. If specified this must be between 1 and 100."
  default     = 5
}
variable "default_nodepool_min_nodes" {
  description = "(Required, when default_nodepool_auto_scaling=true) The minimum number of nodes which should exist in this Node Pool. If specified this must be between 1 and 100."
  default     = 1
}
variable "default_nodepool_node_count" {
  description = "The initial number of nodes which should exist in this Node Pool. If specified this must be between 1 and 100 and between `default_nodepool_min_nodes` and `default_nodepool_max_nodes`."
  default     = 1
}
variable "default_nodepool_os_disk_size" {
  description = "(Optional) The size of the OS Disk which should be used for each agent in the Node Pool. Changing this forces a new resource to be created."
  default     = 128
}
variable "default_nodepool_max_pods" {
  description = "(Optional) The maximum number of pods that can run on each agent. Changing this forces a new resource to be created."
  default     = 110
}
variable "default_nodepool_taints" {
  type    = list(any)
  default = []
}
variable "default_nodepool_labels" {
  type    = map(any)
  default = {}
}
variable "default_nodepool_availability_zones" {
  type    = list(any)
  default = []
}

variable "tags" {
  description = "Map of common tags to be placed on the Resources"
  type        = map(any)
  default     = null
}

variable "defined_tags" {
  description = "Map of common tags to be placed on the Resources"
  type        = map(any)
  default     = null
}

# CAS Nodepool config
variable "create_cas_nodepool" {
  description = "Create the CAS Node Pool"
  type        = bool
  default     = true
}
variable "cas_nodepool_vm_type" {
  default = "VM.Standard.E4.Flex" # default 8 ocpu
}
variable "cas_nodepool_os_disk_size" {
  default = 200
}
variable "cas_nodepool_node_count" {
  default = 1
}
variable "cas_nodepool_auto_scaling" {
  default = true
}
variable "cas_nodepool_max_nodes" {
  default = 5
}
variable "cas_nodepool_min_nodes" {
  default = 1
}
variable "cas_nodepool_taints" {
  type    = list(any)
  default = ["workload.sas.com/class=cas:NoSchedule"]
}
variable "cas_nodepool_labels" {
  type = map(any)
  default = {
    "workload.sas.com/class" = "cas"
  }
}
variable "cas_nodepool_availability_zones" {
  type    = list(any)
  default = []
}

# Compute Nodepool config
variable "create_compute_nodepool" {
  description = "Create the Compute Node Pool"
  type        = bool
  default     = true
}
variable "compute_nodepool_vm_type" {
  default = "VM.Standard.E4.Flex" # default 8 ocpu
}
variable "compute_nodepool_os_disk_size" {
  default = 200
}
variable "compute_nodepool_node_count" {
  default = 1
}
variable "compute_nodepool_auto_scaling" {
  default = true
}
variable "compute_nodepool_max_nodes" {
  default = 5
}
variable "compute_nodepool_min_nodes" {
  default = 1
}
variable "compute_nodepool_taints" {
  type    = list(any)
  default = ["workload.sas.com/class=compute:NoSchedule"]
}
variable "compute_nodepool_labels" {
  type = map(any)
  default = {
    "workload.sas.com/class"        = "compute"
    "launcher.sas.com/prepullImage" = "sas-programming-environment"
  }
}
variable "compute_nodepool_availability_zones" {
  type    = list(any)
  default = []
}

# Connect Nodepool config
variable "create_connect_nodepool" {
  description = "Create the Connect Node Pool"
  type        = bool
  default     = true
}
variable "connect_nodepool_vm_type" {
  default = "VM.Standard.E4.Flex" # default 8 ocpu
}
variable "connect_nodepool_os_disk_size" {
  default = 200
}
variable "connect_nodepool_node_count" {
  default = 1
}
variable "connect_nodepool_auto_scaling" {
  default = true
}
variable "connect_nodepool_max_nodes" {
  default = 5
}
variable "connect_nodepool_min_nodes" {
  default = 1
}
variable "connect_nodepool_taints" {
  type    = list(any)
  default = ["workload.sas.com/class=connect:NoSchedule"]
}
variable "connect_nodepool_labels" {
  type = map(any)
  default = {
    "workload.sas.com/class"        = "connect"
    "launcher.sas.com/prepullImage" = "sas-programming-environment"
  }
}
variable "connect_nodepool_availability_zones" {
  type    = list(any)
  default = []
}

# Stateless Nodepool config
variable "create_stateless_nodepool" {
  description = "Create the Stateless Node Pool"
  type        = bool
  default     = true
}
variable "stateless_nodepool_vm_type" {
  default = "VM.Standard.E4.Flex" # default 8 ocpu
}
variable "stateless_nodepool_os_disk_size" {
  default = 200
}
variable "stateless_nodepool_node_count" {
  default = 1
}
variable "stateless_nodepool_auto_scaling" {
  default = true
}
variable "stateless_nodepool_max_nodes" {
  default = 5
}
variable "stateless_nodepool_min_nodes" {
  default = 1
}
variable "stateless_nodepool_taints" {
  type    = list(any)
  default = ["workload.sas.com/class=stateless:NoSchedule"]
}
variable "stateless_nodepool_labels" {
  type = map(any)
  default = {
    "workload.sas.com/class" = "stateless"
  }
}
variable "stateless_nodepool_availability_zones" {
  type    = list(any)
  default = []
}

# Stateful Nodepool config
variable "create_stateful_nodepool" {
  description = "Create the Stateful Node Pool"
  type        = bool
  default     = true
}
variable "stateful_nodepool_vm_type" {
  default = "VM.Standard.E4.Flex" # default 8 ocpu
}
variable "stateful_nodepool_os_disk_size" {
  default = 200
}
variable "stateful_nodepool_node_count" {
  default = 1
}
variable "stateful_nodepool_auto_scaling" {
  default = true
}
variable "stateful_nodepool_max_nodes" {
  default = 3
}
variable "stateful_nodepool_min_nodes" {
  default = 1
}
variable "stateful_nodepool_taints" {
  type    = list(any)
  default = ["workload.sas.com/class=stateful:NoSchedule"]
}
variable "stateful_nodepool_labels" {
  type = map(any)
  default = {
    "workload.sas.com/class" = "stateful"
  }
}
variable "stateful_nodepool_availability_zones" {
  type    = list(any)
  default = []
}

variable "create_jump_vm" {
  description = "Create bastion host VM"
  default     = null
}

variable "create_jump_public_ip" {
  default = true
}

variable "jump_vm_admin" {
  description = "OS Admin User for Jump VM"
  default     = "jumpuser"
}
