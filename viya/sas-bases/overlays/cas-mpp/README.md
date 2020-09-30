# MPP CAS Server for SAS Viya 4

## Overview

This directory contains files to Kustomize your SAS Viya 4 deployment to use a multi-node 
SAS Cloud Analytic Services (CAS) server, referred to as MPP.

## Instructions

### Edit the kustomization.yaml File

In order to make your CAS server MPP, add a reference to the MPP overlay
to the resources block of the base kustomization.yaml file (`$deploy/kustomization.yaml`).

```yaml
resources:
- sas-bases/overlays/cas-mpp
```

### Modifying the number of CAS Workers

On an MPP CAS Server, the number of workers helps determine the processing power 
of your cluster. The default number of workers 
in the cas-mpp overlay (2) can be modified by using the `cas-add-workers.yaml` example
located in the cas examples directory at `/$deploy/sas-bases/examples/cas/configure`.
The number of workers cannot exceed the number of nodes in your k8s cluster, so ensure 
that you have enough resources to accommodate the value you choose. 

### Additional Modifications

You can make modifications to the overlay through the use of
Patch Transformers. Examples are located in `/$deploy/sas-bases/examples/cas/configure`,
including how to add additional volume mounts and data connectors, modifying CAS
server resource allocation, and changing the default PVC access modes. 

To be included in the manifest, any yaml files containing Patch Transformers must
also be added to the trnsformers block of the base kustomization.yaml file:

```yaml
transformers:
- {{ PATCH-FILE-1 }}
- {{ PATCH-FILE-2 }}
```

### CAS Configuration on an OpenShift Cluster

The `/$deploy/sas-bases/examples/cas/configure` directory contains a file to 
grant Security Context Constraints for fsgroup 26 on an OpenShift cluster. A
Kubernetes cluster administrator should add these Security Context Constraints 
to their OpenShift cluster prior to deploying SAS Viya 4. Use one of the 
following commands:

```yaml
kubectl apply -f cas-scc.yaml
```

or

```yaml
oc create -f cas-scc.yam
```

## Build
After you configure Kustomize, continue your SAS Viya deployment as documented.

## Additional Resources

For more information about the difference between SMP and MPP CAS, see [What is the CAS Server, SMP, and MPP?](http://documentation.sas.com/?softwareId=mysas&softwareVersion=prod&docsetId=itopscon&docsetTarget=n0tx1x9gu37i7qn1nuv8inwzrfet.htm&locale=en#n0dj3c2j49krjhn1jho4z6daw5n1).