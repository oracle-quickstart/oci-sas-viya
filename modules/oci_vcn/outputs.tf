output "vcn_id" {
  value = oci_core_vcn.vnet.id
}

output "nat_route_table_id" {
  value = oci_core_route_table.nat.id
}

output "nat_gateway_ip" {
  value = oci_core_nat_gateway.nat.nat_ip
}
