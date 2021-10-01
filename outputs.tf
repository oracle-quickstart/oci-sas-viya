/*
# #aks
output "aks_host" {
  value = module.aks.host
}
*/

output "nat_gateway_ip" {
  value = module.vnet.nat_gateway_ip
}


output "kube_config" {
  value = module.oke.kube_config
}

/*
output "aks_cluster_node_username" {
  value = module.oke.cluster_username
}
*/
/*
output "aks_cluster_password" {
  value = module.aks.cluster_password
}
*/

#postgres
## az2oci: Postgress settings forced to null - no OCI Postgres service.
output "postgres_server_name" {
  value = null # var.create_postgres ? module.postgresql.postgres_server_name : null
}
output "postgres_fqdn" {
  value = null # var.create_postgres ? module.postgresql.postgres_server_fqdn : null
}
output "postgres_admin" {
  value = null # var.create_postgres ? "${module.postgresql.postgres_administrator_login}@${module.postgresql.postgres_server_name}" : null
}
output "postgres_password" {
  value = null # var.create_postgres ? module.postgresql.postgres_administrator_password : null
}
output "postgres_server_id" {
  value = null # var.create_postgres ? module.postgresql.postgres_server_id : null
}
output "postgres_server_port" {
  value = null # var.create_postgres ? "5432" : null
}


# jump server
output jump_private_ip {
  value = local.create_jump_vm ? module.jump.private_ip_address : null
}

output jump_public_ip {
  value = local.create_jump_vm && var.create_jump_public_ip ? module.jump.public_ip_address : null
}

output jump_admin_username {
  value = local.create_jump_vm ? module.jump.admin_username : null
}

output jump_private_key_pem {
  value = local.create_jump_vm ? module.jump.private_key_pem : null
}

output jump_public_key_pem {
  value = local.create_jump_vm ? module.jump.public_key_pem : null
}

output jump_public_key_openssh {
  value = local.create_jump_vm ? module.jump.public_key_openssh : null
}


# nfs server
## az2oci: TODO nfs settings forced to null, nfs module snot implemented, using OCI FSS instead
output nfs_private_ip {
  value = null # var.storage_type == "standard" ? module.nfs.private_ip_address : null
}

output nfs_public_ip {
  value = null # var.storage_type == "standard" && var.create_nfs_public_ip ? module.nfs.public_ip_address : null
}

output nfs_admin_username {
  value = null # var.storage_type == "standard" ? module.nfs.admin_username : null
}

output nfs_private_key_pem {
  value = null # var.storage_type != "dev" ? module.nfs.private_key_pem : null
}

output nfs_public_key_pem {
  value = null # var.storage_type != "dev" ? module.nfs.public_key_pem : null
}

output nfs_public_key_openssh {
  value = null # var.storage_type != "dev" ? module.nfs.public_key_openssh : null
}


output oke_private_key_pem {
  value = var.storage_type != "dev" ? module.oke.private_key_pem : null
}

/*
# acr
## az2oci: TODO how to get ocir details?
output "acr_id" {
  value = module.acr.acr_id
}

output "acr_url" {
  value = module.acr.acr_login_server
}
*/

# az2oci: location ~= region
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
  # value = var.storage_type != "dev" ? coalesce(module.fss.mount_target_ip, module.nfs.private_ip_address, "") : null
  value = var.storage_type != "dev" ? module.fss.mount_target_ip : null
}

output "rwx_filestore_path" {
  value = var.storage_type != "dev" ? coalesce(module.fss.export_path, "/export") : null
}

/*
output "rwx_filestore_config" {
  value = var.storage_type == "ha" ? jsonencode({
    "version" : 1,
    "storageDriverName" : "azure-netapp-files",
    "subscriptionID" : split("/", data.azurerm_subscription.current.id)[2],
    "tenantID" : "${data.azurerm_subscription.current.tenant_id}",
    "clientID" : "${var.client_id}",
    "clientSecret" : "${var.client_secret}",
    "location" : "${module.azure_rg.location}",
    "serviceLevel" : "${var.netapp_service_level}",
    "virtualNetwork" : "${azurerm_virtual_network.vnet.name}",
    "subnet" : "${module.netapp.netapp_subnet}",
    "defaults" : {
      "exportRule" : "${local.vnet_cidr_block}",
    }
  }) : null
}
*/

## az2oci: TODO REMOVE. for reference, command to ssh to node hosts
output "zzz_proxy_jump" {
  value = local.create_jump_vm ? "ssh -o ProxyCommand=\"ssh -W %h:%p opc@${module.jump.public_ip_address} -i ./jump_id_rsa\" opc@<oke_node_ip> -i ./oke_id_rsa" : null
}
