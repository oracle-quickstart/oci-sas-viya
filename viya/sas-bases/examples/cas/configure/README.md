# Configuration Settings for CAS

## Overview

This document describes the customizations that can be made by the Kubernetes
administrator for deploying CAS in both symmetric multiprocessing (SMP) and
massively parallel processing (MPP) configurations.

An SMP server requires one Kubernetes node. An MPP server requires one
Kubernetes node for the server controller and two or more nodes for server
workers. The _SAS Viya: Deployment Guide_ provides information to help you
decide. A link to the deployment guide is provided in the
[Additional Resources](#additional-resources) section.

## Installation

SAS provides example files for many common customizations. Read the descriptions
for the example files in the following list. If you want to use an example file
to simplify customizing your deployment, copy the file to your
`$deploy/site-config` directory.

Each file has information about its content. The variables in the file are set
off by curly braces and spaces, such as {{ NUMBER-OF-WORKERS }}. Replace the
entire variable string, including the braces, with the value you want to use.

After you edit a file, add a reference to it in the transformer block of the
base `kustomization.yaml` file.

## Examples

The example files are located at `$deploy/sas-bases/examples/cas/configure`. The
following is a list of each example file for CAS settings and the file name.

- mount non-NFS persistentVolumeClaims and data connectors for the CAS server
  (`cas-add-host-mount.yaml`)

- mount NFS persistentVolumeClaims and data connectors for the CAS server
  (`cas-add-nfs-mount.yaml`)

- specify the number of workers in an MPP deployment (`cas-add-workers.yaml`)

  **Note**: Do not use this example for an SMP CAS server.

- add a backup controller to an MPP deployment (`cas-add-backup.yaml`)

  **Note**: Do not use this example for an SMP CAS server.

- change the user the CAS process runs as (`cas-modify-user.yaml`)

- modify the storage size for CAS PersistentVolumeClaims
  (`cas-modify-pvc-storage.yaml`)

- manage resources for CPU and memory (`cas-manage-cpu-and-memory.yaml`)

- modify the resource allocation for ephemeral storage
  (`cas-modify-ephemeral-storage.yaml`)

- add a configMap to your CAS server (`cas-add-configmap.yaml`)

- add environment variables (`cas-add-environment-variables.yaml`)

- add a configMap with an SSSD configuration (`cas-sssd-example.yaml`)

  **Note:** This file has no variables. It is an example of how to create a
  configMap for SSSD.

- modify the accessModes on the CAS permstore and data PVCs
  (`cas-storage-access-modes.yaml`)

- grant Security Context Constraints on an OpenShift cluster (`cas-scc.yaml`)

- disable the sas-backup-agent sidecar from running
  (`cas-disable-backup-agent.yaml`)

## Additional Resources

For more information about CAS configuration and using example files, see the
[SAS Viya: Deployment Guide](http://documentation.sas.com/?softwareId=mysas&softwareVersion=prod&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm).
