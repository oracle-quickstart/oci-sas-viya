# Configuration Settings for PostgreSQL Replicas Count

## Overview

PostgreSQL High Availability (HA) cluster deployments have one master database
and one or more standby databases. Data is replicated from the master database
to the standby database. In Kubernetes, a standby database is referred to as
a replica. This readme describes how to configure the number of replicas in
a PostgreSQL HA cluster.

## Installation

1. The example file contains comments to assist in revising the file
   appropriately.

2. The variable in the file is set off by curly braces and spaces, such as
   {{ REPLICAS-COUNT }}. Replace the entire variable string, including the
   braces, with the value you want to use.

3. After you have edited the file, add a reference to it in the transformer
   block of the base kustomization.yaml file.

## Examples

The example file is located at
`sas-bases/examples/configure-postgres/internal/replicas/postgres-replicas-transformer.yaml`.

## Additional Resources

For more information about using the example file, see the
[SAS Viya Deployment Guide](http://documentation.sas.com/?softwareId=mysas&softwareVersion=prod&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm).

For more information about pgo.yaml configuration, go
[here](https://access.crunchydata.com/documentation/postgres-operator/4.2.2/configuration/pgo-yaml-configuration/).