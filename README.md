# SAS Viya 4 Infrastructure as Code (IaC) for OCI

## Overview

This project contains Terraform scripts to provision Oracle Cloud Infrastructure
(OCI) resources required to deploy SAS Viya 4 products. Here is a list of resources this project will create -

  >- A VCN with subnets
  >- An OKE cluster and 5 nodepools
  >- An NFS share using the OCI FSaaS
  >- A jump box

## Prerequisites
Operational knowledge of:

- [Terraform](https://www.terraform.io/intro/index.html)
- [Docker](https://www.docker.com/)
- [OCI](https://www.oracle.com/cloud/)
- [Kubernetes](https://kubernetes.io/docs/concepts/)

### OCI
First off you'll need to do some pre deploy setup to configure terraform detailed
[here](https://github.com/oracle/oci-quickstart-prerequisites).

You will also need the OCI CLI installed and configured by following these
[instructions](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm)

### SAS Viya

https://my.sas.com/en/my-orders.html
https://apiportal.sas.com/get-started

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

Once complete the kubernetes config will be written to `viya-oke-kubeconfig.conf`

### Install Viya

The install of Viya 4 is done by following the steps detailed
[here](https://github.com/sassoftware/viya4-deployment). Clone that repo and
complete the prerequisite steps for docker [here](https://github.com/sassoftware/viya4-deployment/blob/main/docs/user/DockerUsage.md).


Currently the OCI CLI is not in the default docker build. Replace the Dockerfile from `viya-deployment` with the one in this
repo in `./deployment/Dockerfile`

An example/minimal `ansible-vars.yaml` can be found in `./deployment/ansible-vars.yaml.example`.
Replace all `XXX` values with your values and copy that file to `viya-deployment`.

You can now run the commands below. Note the flag `--volume $HOME/.oci:/viya4-deployment/.oci \`
is OCI specific and allows the OCI CLI inside docker to auth using your user/credentials.

```
docker build -t viya4-deployment .

docker run --rm \
  --group-add root \
  --user $(id -u):$(id -g) \
  --volume $HOME:/data \
  --volume $HOME/repos/oci-sas-viya/viya-oke-kubeconfig.conf:/config/kubeconfig \
  --volume $HOME/repos/viya4-deployment/ansible-vars.yaml:/config/config \
  --volume $HOME/repos/oci-sas-viya/terraform.tfstate:/config/tfstate \
  --volume $HOME/.ssh/oci:/config/jump_svr_private_key \
  --volume $HOME/.oci:/viya4-deployment/.oci \
  viya4-deployment --tags "baseline,viya,install"
```

https://viya.viya.internal/SASLogon/login

### BAD INSTRUCTIONS Install Viya

The install of Viya 4 is done by following the steps detailed
[here](https://github.com/sassoftware/viya4-deployment). Clone that repo and
complete the prerequisite steps for ansible [here](https://github.com/sassoftware/viya4-deployment#ansible-1).

Note:
- The docker method is not currently supported, ansible must be used.
- You must use `kustomize` v3.7.0 available [here](https://github.com/kubernetes-sigs/kustomize/releases/tag/kustomize%2Fv3.7.0), do not use `brew`
- The full list of dependencies is [here](https://github.com/sassoftware/viya4-deployment/blob/main/docs/DEPENDENCY-VERSIONS.md)

An example of a minimal `ansible-vars.yaml.example` is in the `./deployment/` directory.

Your order number and API creds can be retrieved from [here](https://apiportal.sas.com/get-started).
