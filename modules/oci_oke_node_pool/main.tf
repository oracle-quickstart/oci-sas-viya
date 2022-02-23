# create node pool

# TODO Node Pool Across ADs

data "oci_core_images" "np_os_image" {
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

resource "oci_containerengine_node_pool" "np" {
  count = var.create_node_pool ? 1 : 0

  compartment_id     = var.compartment_id
  name               = var.node_pool_name
  cluster_id         = var.oke_cluster_id
  kubernetes_version = var.kubernetes_version
  node_shape         = var.instance_shape

  dynamic "node_shape_config" {
    for_each = local.is_flex_shape
    content {
      ocpus = node_shape_config.value
    }
  }

  # node_shape_config {
  #   ocpus = var.node_pool_node_shape_config_ocpus
  # }

  # initial_node_labels {
  #   key = var.node_pool_initial_node_labels_key
  #   value = var.node_pool_initial_node_labels_value
  # }

  # node_metadata = var.node_pool_node_metadata

  node_config_details {
    size = var.node_count
    placement_configs {
      availability_domain = var.availability_domains[0]
      subnet_id           = var.subnet_id
    }
  }

  node_source_details {
    image_id                = data.oci_core_images.np_os_image.images[0].id
    source_type             = "IMAGE"
    boot_volume_size_in_gbs = var.os_disk_size
  }

  lifecycle {
    ignore_changes = [
      node_source_details[0].image_id, # don't recreate node pool if source image ocid changes
    ]
  }

  ssh_public_key = var.ssh_public_key

}
