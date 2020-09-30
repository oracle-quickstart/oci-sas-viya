---
category: mirrorRegistry
tocprty: 1
---

# Using a Mirror Registry

## Overview

A mirror registry is a local registry of the software necessary to create your deployment. For SAS Viya, a mirror registry is created with SAS Mirror Manager.

This readme describes how to identify a mirror registry for a SAS Viya deployment.

## Installation

If you are not using a mirror registry, then you do not need to perform these steps.

1. Copy the `sas-bases/examples/mirror/mirror.yaml` file to the top level of the $deploy directory, beside the kustomization.yaml file.

2. Open the mirror.yaml file and replace each instance of {{ MIRROR-HOST }} with the fully qualified domain name (FQDN) of the mirror registry.

3. In the base kustomization.yaml file, add mirror.yaml to the transformers section, immediately after the entry for sas-bases/overlays/required/transformers.yaml.

## Additional Documentation

For more information about mirror repositories and SAS Mirror Manager, see the [SAS Viya Deployment Guide](http://documentation.sas.com/?softwareId=mysas&softwareVersion=prod&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm).
