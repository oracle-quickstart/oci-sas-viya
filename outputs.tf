
output "nat_gateway_ip" {
  value = module.vnet.nat_gateway_ip
}


output "kube_config" {
  value = module.oke.kube_config
  sensitive = true
}

# jump server
output "jump_private_ip" {
  value = local.create_jump_vm ? module.jump.private_ip_address : null
}

output "jump_public_ip" {
  value = local.create_jump_vm && var.create_jump_public_ip ? module.jump.public_ip_address : null
}

output "jump_admin_username" {
  value = local.create_jump_vm ? module.jump.admin_username : null
}

output "jump_private_key_pem" {
  value = local.create_jump_vm ? module.jump.private_key_pem : null
}

output "jump_public_key_pem" {
  value = local.create_jump_vm ? module.jump.public_key_pem : null
}

output "jump_public_key_openssh" {
  value = local.create_jump_vm ? module.jump.public_key_openssh : null
}

output jump_rwx_filestore_path {
  value = "/mnt/viya-share"
}

# nfs server
output "nfs_private_ip" {
  value = null # var.storage_type == "standard" ? module.nfs.private_ip_address : null
}

output "nfs_public_ip" {
  value = null # var.storage_type == "standard" && var.create_nfs_public_ip ? module.nfs.public_ip_address : null
}

output "nfs_admin_username" {
  value = null # var.storage_type == "standard" ? module.nfs.admin_username : null
}

output "nfs_private_key_pem" {
  value = null # var.storage_type != "dev" ? module.nfs.private_key_pem : null
}

output "nfs_public_key_pem" {
  value = null # var.storage_type != "dev" ? module.nfs.public_key_pem : null
}

output "nfs_public_key_openssh" {
  value = null # var.storage_type != "dev" ? module.nfs.public_key_openssh : null
}


output "oke_private_key_pem" {
  value = module.oke.private_key_pem
  sensitive = true
}

output "location" {
  value = var.region
}


output "prefix" {
  value = var.prefix
}

output "cluster_name" {
  value = module.oke.name
}

## az2oci: provider_account ~= tenancy name
output "provider_account" {
  value = data.oci_identity_tenancy.tenancy.name
}

output "provider" {
  value = "oci"
}

output "rwx_filestore_endpoint" {
  value = module.fss.mount_target_ip
}

output "rwx_filestore_path" {
  value = coalesce(module.fss.export_path, "/export")
}

## TODO REMOVE. for reference, command to ssh to node hosts
output "zzz_proxy_jump" {
  value = local.create_jump_vm ? "ssh -o ProxyCommand=\"ssh -W %h:%p opc@${module.jump.public_ip_address} -i ./jump_id_rsa\" opc@<oke_node_ip> -i ./oke_id_rsa" : null
}
