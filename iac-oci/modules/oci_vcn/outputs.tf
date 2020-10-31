output "vcn_id" {
  value = oci_core_vcn.vnet.id
}

output "default_security_list_id" {
  value = oci_core_vcn.vnet.default_security_list_id
}
