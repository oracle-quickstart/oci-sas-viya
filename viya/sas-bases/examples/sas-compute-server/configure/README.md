# Configuration Settings for Compute Server

## Overview

This readme describes the settings available for deploying Compute Server.

## Installation

Based on the following description of different example files, determine if you want to use any example file in your deployment. If you do, copy the example file and place it in your site-config directory.

Each file has information about its content. The variables in the file are set off by curly braces and spaces, such as {{ NUMBER-OF-WORKERS }}. Replace the entire variable string, including the braces, with the value you want to use.

After you have edited the file, add a reference to it in the transformer block of the base kustomization.yaml file.

## Examples

The example files are located at /$deploy/sas-bases/examples/compute-server/configure.

- mount non-NFS persistentVolumeClaims (compute-server-add-host-mount.yaml)
- mount NFS persistentVolumeClaims (compute-server-add-nfs-mount.yaml)

## Additional Resources
For information about PersistentVolumes, see [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/).