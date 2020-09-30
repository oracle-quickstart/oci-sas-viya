# Configure Resource Settings for PostgreSQL Pods

## Overview

This readme describes the resource settings available for deploying PostgreSQL
pods with number of CPUs and memory size for both **Limits**
(maximum resource) and **Request** (mimimum resource) settings. These settings
are available only if you are using an internal version of PostgreSQL.

## Installation

1. The example file is almost entirely commented out. The only part that is
   not commented out is required for the successful operation of the code
   blocks that are described below.

2. Based on the following description of the blocks of code included in the
   example, determine if you want to use any of the example file in your
   deployment. If you do, copy the example file and place it in your
   site-config directory. In the new file, uncomment the block or blocks you
   want to use by removing the number sign (#) and adding a space at the
   beginning of each line in the block. If there are two number signs,
   remove only the first. Make sure block comments are aligned with the yaml
   data structure.

   ***Note:*** As a best practice, SAS recommends that if you change one value,
   you change its companion value. For example, if you change the
   {{ LIMITS-MEMORY-SIZE }}, you should also change {{ REQUEST-MEMORY-SIZE }}.

3. Each block has information about its content. The variables in the block are
   set off by curly braces and spaces, such as {{ LIMITS-MEMORY-SIZE }}. 
   Replace the entire variable string, including the braces, with the value
   you want to use.

4. Ensure the values are enclosed in double quotation marks and, if needed,
   with proper unit values. In Kubernetes, the units for megabytes is Mi
   (such as 512Mi), and the units for gigabytes is Gi (such as 4Gi).

5. The **Request** (minimum resource) value must be less then or equal to the
   **Limits** (maximum resource) value. Do not use zero (0) or negative values.

6. After you have edited the file, add a reference to it in the transformer
   block of the base kustomization.yaml file.

## Examples

The example file is located at
`sas-bases/examples/configure-postgres/internal/pods-resource-limits-settings/postgres-pods-resource-limits-settings-transformer.yaml`.
It includes content for configuring the following settings:

* Specify the PostgreSQL pods Limits (maximum resource) for CPU count
* Specify the PostgreSQL pods Limits (maximum resource) for memory size
* Specify the PostgreSQL pods Request (minimum resource) for CPU count
* Specify the PostgreSQL pods Request (minimum resource) for memory size

## Additional Resources

For more information about using the example file, see the
[SAS Viya Deployment Guide](http://documentation.sas.com/?softwareId=mysas&softwareVersion=prod&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm).

For more information about **Pod CPU resource** configuration, go
[here](https://kubernetes.io/docs/tasks/configure-pod-container/assign-cpu-resource/).

For more information about **Pod memory resource** configuration, go
[here](https://kubernetes.io/docs/tasks/configure-pod-container/assign-memory-resource/).