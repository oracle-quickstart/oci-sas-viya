# Create an Additional CAS Server

## Overview

This readme describes how to create additional CAS server definitions with the
`create-cas-server.sh` script. The script creates a Custom Resource (CR) that
can be added to your manifest and deployed to the Kubernetes cluster.

Running this script creates all of the artifacts that are necessary for
deploying a new CAS server in the Kubernetes cluster in one directory. The
directory can be referenced in the base `kustomization.yaml`.

> The script does not modify your Kubernetes cluster. It creates the manifests
> that you can apply to your Kubernetes cluster to add a CAS server.

## Create a CAS Server

1. Run the `create-cas-server.sh` script and specify, at a minimum, the instance
   name. The instance name is used to label the server and differentiate it from
   the default instance that is provided automatically.

   ```bash
   ./create-cas-server.sh -i {{ INSTANCE }}
   ```

   The sample command creates a top-level directory `cas-{{ INSTANCE }}` that
   contains everything that is required for a new CAS server instance. For
   example, the directory contains the CR, PVC definitions for the permstore and
   data PVs, and so on.

   > The `-o directory-path` argument can be used to specify the parent
   > directory for the output. For example, you can specify
   > `-o $deploy/site-config`. If you do not create the output in that
   > directory, you should move the new directory to `$deploy/site-config`.
   > Run the command with the `--help` argument to view all the options.

2. In the base `kustomization.yaml` file, add the new directory to the resources
   section so that the CAS server is included when the manifest is rebuilt. This
   server is fully customizable with the use of patch transformers.

   ```yaml
   resources:
     - site-config/{{ DIRECTORY-PATH }}/cas-{{ INSTANCE }}
   ```

3. Run `kustomize build` to generate a new manifest and then apply the manifest
   to the namespace in your cluster. These steps create the CAS pods, services,
   and so on, for your new server.

   ```bash
   kubectl get pods -l casoperator.sas.com/server={{ INSTANCE }}
   sas-cas-server-{{ INSTANCE}}-controller     3/3     Running     0          1m

   kubectl get pvc | grep {{ INSTANCE }}
   NAME                                                  STATUS  ...
   cas-{{ INSTANCE }}-data                                Bound  ...
   cas-{{ INSTANCE }}-permstore                           Bound  ...
   ```

## Example

Run the script with more options:

```bash
./create-cas-server.sh --instance sample --output . --workers 2 --backup 1
```

This sample command creates a new directory `cas-sample` in the current location
and creates a new CAS distributed server (MPP) CR with 2 worker nodes and a
backup controller.
