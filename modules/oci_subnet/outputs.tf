output "subnet_id" {
  value = oci_core_subnet.subnet.id
}

output "subnet_name" {
  value = oci_core_subnet.subnet.display_name
}