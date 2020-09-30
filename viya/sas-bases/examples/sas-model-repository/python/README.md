# Configure Python for SAS Model Repository Service

## Overview

The Python restore script for the SAS Model Repository service enables users to restore projects that contain analytic store and Python models, 
along with their associated resources and analytic store files. The restore script can be used in a customer-prepared environment that consists of a Python
installation with any required packages that are stored in a Kubernetes persistent volume. 

This readme describes how to make that volume available to your deployment.

## Prerequisites

SAS Viya provides YAML files that the Kustomize tool uses to configure Python. Before you use those files, you must perform the following tasks:

1. Make note of the attributes for the volume where Python and the associated packages are to be deployed. For example, for
  NFS, note the NFS server and directory. For more information about the various types of persistent volumes in Kubernetes,
   see [Additional Resources] (#additional-resources).
2. Install Python and any necessary packages on the volume.

## Installation

1. Copy the files in the `$deploy/sas-bases/examples/sas-model-repository/python` directory
to the `$deploy/site-config/sas-model-repository/python` directory. Create the target directory, if
it does not already exist.

2. Attach storage to your SAS Viya deployment. 
The python-transformer.yaml file uses PatchTransformers in Kustomize
to attach the volume containing your Python installation to SAS Viya. 
Replace {{ VOLUME-ATTRIBUTES }} with the appropriate volume specification. 
For example, when using an NFS mount, the {{ VOLUME-ATTRIBUTES }} tag should be
replaced with `nfs: {path: /vol/python, server: myserver.sas.com}`
where `myserver.sas.com` is the NFS server and `/vol/python` is the
NFS path that you recorded in the [Prerequisites](#prerequisites) step.

The relevant code excerpt from python-transformer.yaml file before the change:

```yaml
patch: |-
  # Add Python volume
  - op: add
    path: /spec/template/spec/volumes/-
    value: { name: python-volume, {{ VOLUME-ATTRIBUTES }} }
  # Add mount path for Python
  - op: add
    path: /template/spec/containers/0/volumeMounts/-
    value:
      name: python-volume
      mountPath: /python
      readOnly: true
```

The relevant code excerpt from python-transformer.yaml file after the change:

```yaml
patch: |-
  # Add Python volume
  - op: add
    path: /spec/template/spec/volumes/-
    value: { name: python-volume, nfs: {path: /vol/python, server: myserver.sas.com} }
  # Add mount path for Python
  - op: add
    path: /template/spec/containers/0/volumeMounts/-
    value:
      name: python-volume
      mountPath: /python
      readOnly: true
```

3. Make the following changes to the base kustomization.yaml file in the `$deploy` directory.
* Add site-config/sas-model-repository/python/python-transformer.yaml to the transformers block.

## Additional Resources

* [SAS Viya Deployment Guide](http://documentation.sas.com/?softwareId=mysas&softwareVersion=prod&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm&locale=en)

* [Persistent volumes on Kubernetes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)

* [Types of volumes](https://kubernetes.io/docs/concepts/storage/volumes/#types-of-volumes) and their attributes that are supported by Kubernetes