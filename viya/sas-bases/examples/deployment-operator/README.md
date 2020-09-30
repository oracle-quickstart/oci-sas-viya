---
category: deployOperator
tocprty: 1
---

# SAS Viya Deployment Operator

## Overview

The SAS Viya Deployment Operator can be used to manage SAS deployments in a
single namespace or across the entire cluster.

**Note:** The operator is not part of the SAS Viya deployment but is deployed
in a similar manner within the same cluster as what's described in SAS Viya:
Deployment Guide. There are two distinct projects to manage when utilizing the
operator. The first is for deployment of the operator itself which will watch
for SAS Viya deployment changes to reconcile. Each SAS Viya deployment managed
by the operator is represented by a separate discrete project containing a
custom resource and associated user customizations.

## Deploying the Operator

The `$deploy/sas-bases/examples/deployment-operator/deploy/` directory contains
resources to deploy the operator. The `site-config/transformer.yaml` files,
which provides customization of the operator, is located inside this directory.
Kustomize is used to configure the operator for the target environment.
A sample custom resource providing input to the operator is also included.

To install and customize the operator, perform the following steps.

1. Copy the recursive content of the `$deploy/sas-bases/examples/deployment-operator/deploy`
   directory to the `$deploy` directory, beside the `$deploy/sas-bases` directory.
   The result is a directory structure that looks like this:

   ```
   $deploy
   |-- operator-base/
   |-- sas-bases/
   |-- site-config/
   |   +-- transformer.yaml
   +-- kustomization.yaml
   ```

2. Edit the `$deploy/site-config/transformer.yaml` to set the namespace
   for the target cluster. The default namespace value is `default`.

   ```
   ...
   patch: |-
   # namespace: MUST BE PROVIDED BY USER. DEFAULT VALUE IS 'default'
     - op: add
       path: /subjects/0/namespace
       value:
         default
   ...
   ```

3. Apply the customizations by running the following command from the `$deploy` directory:

   ```
   kustomize build . > manifest.yaml
   ```

4. To install the operator and its supporting resources, run the following command:

   ```
   kubectl apply -f manifest.yaml
   ```

## Using the Operator to Deploy SAS Viya

The SAS Viya Deployment Operator watches the cluster for a `SASDeployment` custom resource.
The data in the SASDeployment custom resource is used by the operator when installing Viya.

In a project separate from the one used to deploy the operator, create and apply a
SASDeployment custom resource to the cluster. A sample custom resource is included in the
`$deploy/sas-bases/examples` directory. To use the sample, perform the following steps.

1. Copy one of the sample `SASDeployment` files from
   `$deploy/sas-bases/examples/deployment-operator/samples` directory as `sasdeployment.yaml`
   to a newly created `$deploy` directory for this SAS Viya deployment. The result is a
   directory structure that looks like this:

   ```
   $deploy
   +-- sasdeployment.yaml
   ```

2. Edit `$deploy/sasdeployment.yaml` to specify the cadence name, version, and release
   information. The snippet below shows the edits made to specify the cadence name and
   version: `stable`, `2020.0.6`. On the first application of the custom resource to the cluster,
   the `cadenceRelease` property can be omitted or given the empty string value as in
   the example below. The operator uses the latest release found in the repository warehouse
   for the specified cadence name and version. To update the initial deployment, however,
   you must explicitly include the `cadenceRelease` property in the custom resource.  Either
   specify the empty string, in which case the operator will choose the latest, or the
   `cadenceRelease` value to which you'd like to upgrade.
   ```
   ...
   spec:
     cadenceName: "stable"
     cadenceVersion: "2020.0.6"
     cadenceRelease: ""
   ...
   ```
   Perform this step in addition to the kustomization.yaml and site-config creation
   described in [SAS Viya: Deployment Guide](http://documentation.sas.com/?softwareId=mysas&softwareVersion=prod&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm).  Your SAS Viya configuration may be embedded
   into the custom resource, or referenced externally with a go-getter URL.

3. Apply the resource to the cluster:

   ```
   kubectl apply -f sasdeployment.yaml
   ```

## Additional Resources

For more information about the SAS Viya Deployment Operator, see
[Using the SAS Viya Deployment Operator](http://documentation.sas.com/?softwareId=mysas&softwareVersion=prod&docsetId=dplyml0phy0dkr&&docsetTarget=p0p81scwp19aghn0z8trji3arf99.htm&locale=en).
