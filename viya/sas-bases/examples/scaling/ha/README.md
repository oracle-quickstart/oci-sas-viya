# High Availability (HA) in SAS Viya 4

## Overview

SAS Viya 4 can be deployed as a High Availability (HA) system. In this mode, SAS
Viya 4 has redundant stateless and stateful services to handle service outages,
such as an errant Kubernetes node.

## Enable High Availability

A kustomize transformer enables High Availability (HA) in SAS Viya 4 among the
stateless microservices. Stateful services, with the exception of SMP CAS, are
enabled HA at initial deployment.

Add the `sas-bases/overlays/scaling/ha/enable-ha-transformer.yaml` to the
transformers block in your base kustomization.yaml file.

```yaml

...
transformers:
...
- sas-bases/overlays/scaling/ha/enable-ha-transformer.yaml
```

To apply the change run `kustomize build -o site.yaml`, then apply the updated
`site.yaml` to your deployment.

## Disable High Availability

To disable HA, remove the transformer you added in the previous step, then run
`kustomize build -o site.yaml` then apply the updated `site.yaml` to your
deployment.
