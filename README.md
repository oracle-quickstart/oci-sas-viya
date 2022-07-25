# SAS Viya 4 Infrastructure as Code (IaC) for OCI

## Overview

This project contains Terraform scripts to provision Oracle Cloud Infrastructure
(OCI) resources required to deploy SAS Viya 4 products. Here is a list of resources this project will create -

  >- A VCN with subnets (optionally)
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

You will need your order information and to generate an API key with the links below:
- https://my.sas.com/en/my-orders.html
- https://apiportal.sas.com/get-started

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

Once complete the kubernetes config will be written to `viya-oke-kubeconfig.conf`.
Any `kubectl` commands below assume you've copied this file to `~/.kube/config`.

### Install Viya

The install of Viya 4 is done by following the steps detailed
[here](https://github.com/sassoftware/viya4-deployment). Clone that repo and
complete the prerequisite steps for docker [here](https://github.com/sassoftware/viya4-deployment/blob/main/docs/user/DockerUsage.md).
The docker method is recomended over ansible. If you are connecting to AutonomousDB
you will need to run commands outside of docker, binary version requirements are
[here](https://github.com/sassoftware/viya4-deployment/blob/main/docs/user/Dependencies.md).

Currently the OCI CLI is not in the default docker build. Replace the Dockerfile from `viya-deployment` with the one in this
repo in `./deployment/Dockerfile`

An example/minimal `ansible-vars.yaml` can be found in `./deployment/ansible-vars.yaml.example`.
Replace all `XXX` values with your values and copy that file to `viya-deployment`.

The ansible var `V4_CFG_INGRESS_FQDN: 'viya.viya.internal'` given in the example
is intended to be set in you local hosts file, eg:
```
cat /etc/hosts | grep viya
# viya
129.158.X.Y viya.viya.internal # not actual ip
```

This can be set to the public ip of the load balancer creating during the viya
install below after it completes. Other DNS options are described [here](https://github.com/sassoftware/viya4-deployment#dns).

You can now run the commands below, or similar docker commands. Note the flag `--volume $HOME/.oci:/viya4-deployment/.oci \`
is OCI specific and allows the OCI CLI inside docker to auth using your user/credentials.
Also the paths defined in `.oci/config` should be relative, eg `key_file=~/.oci/oci_api_key.pem`

```
docker build -t viya4-deployment .

docker run --rm \
  --group-add root \
  --user $(id -u):$(id -g) \
  --env GIT_CEILING_DIRECTORIES=/viya4-deployment \
  --volume $HOME:/data \
  --volume $HOME/repos/oci-sas-viya/viya-oke-kubeconfig.conf:/config/kubeconfig \
  --volume $HOME/repos/viya4-deployment/ansible-vars.yaml:/config/config \
  --volume $HOME/repos/oci-sas-viya/terraform.tfstate:/config/tfstate \
  --volume $HOME/.ssh/oci:/config/jump_svr_private_key \
  --volume $HOME/.oci:/viya4-deployment/.oci \
  viya4-deployment --tags "baseline,viya,install"
```

Once the `docker run` command finishes you can query the readiness pod by running:
```
kubectl wait \
  --for=condition=ready pod \
  --selector="app.kubernetes.io/name=sas-readiness" \
  --timeout=1800s
```
If this returns success, you can log in as the `sasboot` user at: https://viya.viya.internal/SASLogon/login

### Connection to AutonomousDB

Connecting Viya to an instance of ADW requires using kustomize and overlays outside
of docker. Be sure to pay attention to the requiired versions of binarires [here](https://github.com/sassoftware/viya4-deployment/blob/main/docs/user/Dependencies.md)
, and the `yq` helper commands use v4 syntax. Doc for overlays with Viya in general is [here](https://github.com/sassoftware/viya4-deployment#customize-deployment-overlays)

General documentation can be found in doc downloaded at install at path `file://$HOME/viya-oke/viyanamespace/sas-bases/docs/configuring_sasaccess_and_data_connectors_for_sas_viya_4.htm`.

Example commands are included below for conveinence, but fundamentally what we're
doing is:
- mounting the NFS on a pod
- setting required env vars
- making sure the ADW FQDN is resolvable

```
cd $HOME/viya-oke/viyanamespace
cp kustomization.yaml kustomization.yaml.bak
cp site.yaml site.yaml.bak

# pwd -> $HOME/viya-oke/viyanamespace/
mkdir site-config/data-access
cp sas-bases/examples/data-access/data-mounts-cas.sample.yaml ~/viya-oke/viyanamespace/site-config/data-access/data-mounts-cas.yaml
cp sas-bases/examples/data-access/data-mounts-job.sample.yaml ~/viya-oke/viyanamespace/site-config/data-access/data-mounts-job.yaml
cp sas-bases/examples/data-access/data-mounts-deployment.sample.yaml ~/viya-oke/viyanamespace/site-config/data-access/data-mounts-deployment.yaml

chmod 644 site-config/data-access/data*.yaml

# edit each file to add NFS example with correct hostname,
# correctly formatted examples with dummy FQDNs are in oci-sas-viya/deployment
nano site-config/data-access/data-mounts-cas.yaml
nano site-config/data-access/data-mounts-job.yaml
nano site-config/data-access/data-mounts-deployment.yaml

yq -i eval '.transformers += ["site-config/data-access/data-mounts-cas.yaml"]' kustomization.yaml
yq -i eval '.transformers += ["site-config/data-access/data-mounts-deployment.yaml"]' kustomization.yaml
yq -i eval '.transformers += ["site-config/data-access/data-mounts-job.yaml"]' kustomization.yaml

# needed env vars
# ORACLE=$(PATH_TO_ORACLE_LIBS)
# ORACLE_BIN=$(PATH_TO_ORACLE_BIN)
# ORACLE_HOME=$(PATH_TO_ORACLE_HOME)

echo "ORACLE=/access-clients/oracle/instantclient_21_6" \
 > ./site-config/data-access/sas-access.properties

echo "ORACLE_HOME=/access-clients/oracle/instantclient_21_6" \
 >> ./site-config/data-access/sas-access.properties

echo "ORACLE_BIN=/access-clients/oracle/instantclient_21_6" \
 >> ./site-config/data-access/sas-access.properties

# Just append
printf "configMapGenerator:
  - name: sas-access-config
    behavior: merge
    envs:
      - site-config/data-access/sas-access.properties
" >> kustomization.yaml

yq -i eval '.transformers += ["sas-bases/overlays/data-access/data-env.yaml"]' kustomization.yaml

mkdir -p site-config/network

# BOTH ip and FQDN of the ADW need to be defined in the files below
# The ips or FQDNS with XXX, X, or Y below are placeholders to be replaced wiith your values

printf 'apiVersion: builtin
kind: PatchTransformer
metadata:
  name: etc-hosts-cas
patch: |-
  - op: add
    path: /spec/controllerTemplate/spec/hostAliases
    value:
      - ip: 192.168.X.Y
        hostnames:
        - "XXX.adb.us-ashburn-1.oraclecloud.com"
target:
  kind: CASDeployment
  annotationSelector: sas.com/sas-access-config=true
' > site-config/network/etc-host-cas.yaml


printf 'apiVersion: builtin
kind: PatchTransformer
metadata:
  name: etc-hosts-job
patch: |-
  - op: add
    path: /template/spec/hostAliases
    value:
      - ip: 192.168.X.Y
        hostnames:
        - "XXX.adb.us-ashburn-1.oraclecloud.com"
target:
  kind: PodTemplate
  annotationSelector: sas.com/sas-access-config=true
' > site-config/network/etc-host-job.yaml


# check yaml
yq e site-config/network/etc-host-cas.yaml && echo "\n\n\n" && yq e site-config/network/etc-host-job.yaml

yq -i eval '.transformers += ["site-config/network/etc-host-cas.yaml"]' kustomization.yaml
yq -i eval '.transformers += ["site-config/network/etc-host-job.yaml"]' kustomization.yaml


# generate site.yaml to include
kustomize build -o site.yaml

# apply site.yaml
kubectl apply --kubeconfig=$HOME/repos/oci-sas-viya/viya-oke-kubeconfig.conf --selector="sas.com/admin=namespace" -f site.yaml --prune
```

Once these customizations have been applied you can sanity check hostnames/mounts
with the below commands:
```
# sanity check mount
kubectl -n viyanamespace exec -it sas-cas-server-default-controller -- df -k
kubectl -n viyanamespace exec -it sas-cas-server-default-controller -- ls -al /access-clients/oracle

# sanity check db in /etc/hosts
kubectl -n viyanamespace exec -it sas-cas-server-default-controller -- cat /etc/hosts

# sanity check for $ORACLE_XXX in env?
kubectl -n viyanamespace exec -it sas-cas-server-default-controller -- env | grep 'ORACLE\|LIBRARY'
```

Additionally, a user that is not `sasboot` should be created if one does not exist
for SAS Studio connections to ADW. In Studio the libname statment uses the coonnection
string from you ADW is a form like (replacing XXX values):
```
ibname autodb oracle user="admin" password="XXX" path="(description= (retry_count=20)(retry_delay=3)(address=(protocol=tcps)(port=1521)(host=XXX.adb.us-ashburn-1.oraclecloud.com))(connect_data=(service_name=XXX.adb.oraclecloud.com))(security=(ssl_server_dn_match=yes)))";

```
