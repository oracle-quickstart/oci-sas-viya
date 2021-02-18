output "vcn_id" {
  value = oci_core_vcn.vnet.id
}

output "nat_route_table_id" {
  value = oci_core_route_table.nat.id
}