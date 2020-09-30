# SAS GPU Reservation Service

## Overview

The SAS GPU Reservation Service aids SAS processes in resource sharing and
utilization of the Graphic Processing Units (GPUs) that are available in a
Kubernetes Pod. It is required in every SAS Cloud Analytic Services (CAS) CAS
Pod that is GPU-enabled.

## Installation

The `cas-gpu-patch.yaml` file is located at `$deploy/sas-bases/examples/gpu`.
Copy the entire `gpu` directory to your `$deploy/site-config` directory.

In the copy of `cas-gpu-patch.yaml` in the copied `gpu` directory, specify the
number of required GPUs. The values for the resource requests and resource
limits must be the same and should not exceed the maximum number of GPU devices
on a single node. In the cas-gpud-sidecar section, consider whether you require
a different level of information from the GPU server. The value for
SASGPUD_LOG_TYPE can be info, json, debug, or trace. Save and close the new
file.

After you edit the file, add the following references to the base
`kustomization.yaml` file:

- Add the path to the `cas-gpu-patch.yaml` file as the first entry in the
  transformers block.
- Add the path to the `kustomizeconfig.yaml` file to the configurations block.
  If the configurations block does not exist yet, create it.

For example, if you copied the files to `$deploy/site-config/gpu`, the
references would look like the following sample:

```yaml
---
transformers:
  - site-config/gpu/cas-gpu-patch.yaml
---
configurations:
  - site-config/gpu/kustomizeconfig.yaml
```

## Additional Resources

For more information about using example files, see the
[SAS Viya: Deployment Guide](http://documentation.sas.com/?softwareId=mysas&softwareVersion=prod&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm).
