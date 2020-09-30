# Enable or Disable TLS on PostgreSQL Servers

## Overview

This readme describes the steps to enable or disable TLS for an internal 
instance of PostgreSQSL in your SAS Viya deployment.

## Installation

**Note:** These instructions only apply to the internal instance of
PostgreSQL server. If you are using an external instance of PostgreSQL,
do not perform any of these steps.

### Enable TLS
To enable your deployment to use a TLS/SSL enabled PostgreSQL, add the
following configMapGenerator to the base kustomization.yaml file
(`$deploy/kustomization.yaml`):

```yaml
configMapGenerator:
- name: sas-postgres-config
  literals:
  - DATABASE_SSL_ENABLED="true"
  behavior: merge
```

### Disable TLS
**Note:** TLS is disabled by default. This step is only necessary if you
previously enabled TLS on the PostgreSQL servers and wish to disable it.

To disable your deployment from using a TLS/SSL enabled PostgreSQL, add the
following configMapGenerator to your base kustomization.yaml file
(`$deploy/kustomization.yaml`):

```yaml
configMapGenerator:
- name: sas-postgres-config
  literals:
  - DATABASE_SSL_ENABLED="false"
  behavior: merge
```

## Additional Resources
For more information about the differences between internal and external instances
of PostgreSQL, see
[SAS Infrastructure Data Server Requirements](http://documentation.sas.com/?softwareId=mysas&softwareVersion=prod&docsetId=itopssr&docsetTarget=n1rbbuql9epqa0n1pg3bvfx3dmvc.htm).