output "instance_nsg_id" {
  value = oci_core_network_security_group.instance-nsg.id
}

output "mount_target_ip" {
  value = data.oci_core_private_ip.mt_ip.ip_address
}

output "export_path" {
  value = oci_file_storage_export.exp.path
}