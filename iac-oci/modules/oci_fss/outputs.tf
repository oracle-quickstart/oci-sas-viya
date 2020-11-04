output "instance_nsg_id" {
  value = oci_core_network_security_group.instance-nsg.id
}

output "fss_mt_private_ip" {
  value = data.oci_core_private_ip.mt_ip.ip_address
}