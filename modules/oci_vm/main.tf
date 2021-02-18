

resource "oci_core_public_ip" "vm_ip" {
  count          = var.create_public_ip ? 1 : 0
  compartment_id = var.compartment_id
  display_name   = "${var.name}-public_ip"
  lifetime       = "RESERVED"
  private_ip_id  = data.oci_core_private_ips.vm_private_ip.private_ips[0].id
  freeform_tags  = var.freeform_tags
  defined_tags   = var.defined_tags
}

data "oci_core_private_ips" "vm_private_ip" {
  subnet_id  = var.subnet_id
  ip_address = oci_core_instance.vm[0].private_ip
}

resource "oci_core_volume" "vm_data_disk" {
  count               = var.create_vm ? var.data_disk_count : 0
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_id
  display_name        = format("%s-disk%02d", var.name, count.index + 1)
  size_in_gbs         = var.data_disk_size
  freeform_tags       = var.freeform_tags
  defined_tags        = var.defined_tags
}

resource "oci_core_volume_attachment" "test_volume_attachment" {
  count           = var.create_vm ? var.data_disk_count : 0
  attachment_type = "PARAVIRTUALIZED"
  instance_id     = oci_core_instance.vm[0].id
  volume_id       = oci_core_volume.vm_data_disk[count.index].id
}

resource "tls_private_key" "private_key" {
  count     = var.ssh_public_key == "" ? 1 : 0
  algorithm = "RSA"
}

data "tls_public_key" "public_key" {
  count           = var.ssh_public_key == "" ? 1 : 0
  private_key_pem = element(coalescelist(tls_private_key.private_key.*.private_key_pem), 0)
}

locals {
  ssh_public_key = var.ssh_public_key != "" ? var.ssh_public_key : element(coalescelist(data.tls_public_key.public_key.*.public_key_openssh, [""]), 0)
}

data "oci_core_images" "vm_os_image" {
  compartment_id           = var.compartment_id
  operating_system         = var.operating_system
  operating_system_version = var.operating_system_version
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
  state                    = "AVAILABLE"

  filter {
    name = "display_name"
    # This pattern ensure speciallised OSs (e.g. for GPU instances) are ignored
    values = ["^([a-zA-z]+)-([a-zA-z]+)-([0-9\\.]+)-([0-9]+)"]
    regex  = true
  }
}

resource "oci_core_instance" "vm" {
  count = var.create_vm ? 1 : 0

  availability_domain  = var.availability_domain
  compartment_id       = var.compartment_id
  shape                = var.instance_shape
  display_name         = "${var.name}-vm"
  preserve_boot_volume = false # boot volume will be deleted on destroy

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.vm_os_image.images[0].id
    boot_volume_size_in_gbs = var.os_disk_size
  }

  lifecycle {
    ignore_changes = [
      source_details[0].source_id, # don't recreate instance if source image ocid changes
    ]
  }

  metadata = {
    ssh_authorized_keys = local.ssh_public_key
    user_data           = var.cloud_init != "" ? var.cloud_init : null
  }

  create_vnic_details {
    assign_public_ip = false # reserved public IP manually attached
    display_name     = "${var.name}-nic"
    hostname_label   = var.name
    nsg_ids          = var.nsg_ids
    subnet_id        = var.subnet_id
    freeform_tags    = var.freeform_tags
    defined_tags     = var.defined_tags
  }

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}
