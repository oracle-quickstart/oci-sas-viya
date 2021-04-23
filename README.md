# SAS Viya 4 Infrastructure as Code (IaC) for OCI

## Overview

This project contains Terraform scripts to provision Oracle Cloud Infrastructure
(OCI) resources required to deploy SAS Viya 4 products. Here is a list of resources this project will create -

  >- A VCN with subnets
  >- An OKE cluster and 5 nodepools
  >- An NFS share using the OCI FSaaS
  >- A jump box

## Prerequisites

First off you'll need to do some pre deploy setup.  That's all detailed [here](https://github.com/oracle/oci-quickstart-prerequisites).

Operational knowledge of:

- [Terraform](https://www.terraform.io/intro/index.html)
- [Docker](https://www.docker.com/)
- [OCI](https://www.oracle.com/cloud/)
- [Kubernetes](https://kubernetes.io/docs/concepts/)


## Draft Deploy Steps

### Clone
```
git clone https://github.com/oracle-quickstart/oci-sas-viya.git
cd ./oci-sas-viya
```

### Deploy IaaS
All Terraform variables have defaults. All resources will be prefixed with
`var.prefix` which by default is `viya` Simply:
```
terraform plan #optional, to see what resources will be created
terraform apply
```
Once complete the kubernetes config will be written to ``

### Install Viya

The install of Viya 4 is done by following the steps detailed
[here](https://github.com/sassoftware/viya4-deployment). Clone that repo and
complete the prerequisite steps for ansible [here](https://github.com/sassoftware/viya4-deployment#ansible-1).

Note:
- The docker method is not currently supported, ansible must be used.
- You must use `kustomize` v3.7.0 available [here](https://github.com/kubernetes-sigs/kustomize/releases/tag/kustomize%2Fv3.7.0), do not use `brew`
- The full list of dependencies is [here](https://github.com/sassoftware/viya4-deployment/blob/main/docs/DEPENDENCY-VERSIONS.md)

An example of a minimal `ansible-vars.yaml` is below:

```
## Cluster
PROVIDER: custom
CLUSTER_NAME: mycluster
NAMESPACE: viyanamespace

## MISC
DEPLOY: true # Set to false to stop at generating the manifest
# NAT gateway ip + everything for testing
LOADBALANCER_SOURCE_RANGES: ['132.226.34.29/32', '0.0.0.0/0']

## Storage
V4_CFG_MANAGE_STORAGE: true

## SAS API Access
# Raw not base64 encoded
V4_CFG_SAS_API_KEY: 'your_key'
V4_CFG_SAS_API_SECRET: 'your_secret'
V4_CFG_ORDER_NUMBER:  'your_order_number'

## Ingress
V4_CFG_INGRESS_TYPE: ingress
V4_CFG_INGRESS_FQDN: 'viya.viya.oraclevcn.com'
V4_CFG_TLS_MODE: "full-stack" # [full-stack|front-door|disabled]

## Postgres
V4_CFG_POSTGRES_TYPE: internal

## peg cadence
V4_CFG_CADENCE_NAME: stable
V4_CFG_CADENCE_VERSION: 2020.1.4
```

Your order number and API creds can be retrieved from [here](https://apiportal.sas.com/get-started).
