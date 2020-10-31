# create oci file storage system


resource "oci_file_storage_file_system" "fs" {
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_id

  display_name = var.name
  # TODO add option to provide kms key
  # kms_key_id = var.key.id

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_file_storage_mount_target" "mt" {
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_id
  subnet_id           = var.subnet_id
  display_name        = "${var.name}-mt"

  nsg_ids = [oci_core_network_security_group.mt-nsg.id]

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}



resource "oci_file_storage_export_set" "exp-set" {
  mount_target_id = oci_file_storage_mount_target.mt.id
  display_name    = "${var.name}-exp-set"
}

resource "oci_file_storage_export" "exp" {
  export_set_id  = oci_file_storage_export_set.exp-set.id
  file_system_id = oci_file_storage_file_system.fs.id
  path           = var.path

  export_options {
    source                         = var.source_cidr
    access                         = "READ_WRITE"
    identity_squash                = "NONE"
    require_privileged_source_port = true
  }
}
