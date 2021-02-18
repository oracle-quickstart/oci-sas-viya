output "private_ip_address" {
  value = var.create_vm ? element(coalescelist(oci_core_instance.vm.*.private_ip, [""]), 0) : null
}

output "public_ip_address" {
  value = var.create_vm ? element(coalescelist(oci_core_public_ip.vm_ip.*.ip_address, [""]), 0) : null
}

output "admin_username" {
  value = var.create_vm ? var.vm_admin : null
}

output "private_key_pem" {
  value = var.ssh_public_key == "" ? element(coalescelist(data.tls_public_key.public_key.*.private_key_pem, [""]), 0) : null
}

output "public_key_pem" {
  value = var.ssh_public_key == "" ? element(coalescelist(data.tls_public_key.public_key.*.public_key_pem, [""]), 0) : null
}

output "public_key_openssh" {
  value = var.ssh_public_key == "" ? element(coalescelist(data.tls_public_key.public_key.*.public_key_openssh, [""]), 0) : null
}