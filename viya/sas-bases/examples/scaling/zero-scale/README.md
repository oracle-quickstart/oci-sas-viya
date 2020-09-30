# Zero Scaling SAS Viya 4

## Overview

SAS Viya 4 has the capability to scale to zero the following processes. Scaling
down a process also shuts it down.

- microservices
- cron jobs
- daemonsets
- stateful services
  - RabbitMQ
  - Consul
  - Cacheserver and Cachelocator
  - CAS
  - internal instances of PostgreSQL

When scaling down is complete, any storage provisioned by Kubernetes for SAS
Viya 4 will still be active so the system can be scaled back up again.
Additionally, scaling down does not stop active compute jobs.

## Scale Down Process

### Initial Phase (Phase 0)

A series of kustomize transformers will scale the SAS Viya deployment to zero
and back again. Note that even though SAS performs an ordered shutdown, this
test ensures the operators are available to shut down the resources they own.

Add `sas-bases/overlays/scaling/zero-scale/phase-0-transformer.yaml` to the
transformers block in your base kustomization.yaml file. Here is an example:

```yaml
...
transformers:
...
- sas-bases/overlays/scaling/zero-scale/phase-0-transformer.yaml
```

To apply the change, run `kustomize build -o site.yaml` then apply the updated
site.yaml file to your deployment.

### Phase 1

Add the `sas-bases/overlays/scaling/zero-scale/phase-1-transformer.yaml` to the
transformers block in your base kustomization.yaml file.

```yaml
...
transformers:
...
- sas-bases/overlays/scaling/zero-scale/phase-0-transformer.yaml
- sas-bases/overlays/scaling/zero-scale/phase-1-transformer.yaml
```

To apply the change, run `kustomize build -o site.yaml` then apply the updated
site.yaml to your deployment.

### Scale down an Internal Instance of PostgreSQL

To scale an internal instance of PostgreSQL to zero, run the following command
as an administrator with namespace permissions:

`kubectl -n <name-of-namespace> scale deployment --selector='pg-cluster=sas-crunchy-data-postgres' --replicas=0`

## Scale Up Process

To scale back up, remove the two transformers you added in the previous steps.
Run `kustomize build -o site.yaml`, then apply the updated site.yaml file to
your deployment.

If you have internal instance of PostgreSQL, run the following command as an
administrator with namespace permissions:

`kubectl -n <name-of-namespace> scale deployment --selector='pg-cluster=sas-crunchy-data-postgres' --replicas=1`
