# Configuration Settings for PostgreSQL Storage Size, Storage Class, Storage Type, and Storage Access Mode

## Overview

This readme describes the settings available for deploying PostgreSQL with
custom size, storage class, storage type, and storage access mode. These
settings are available only if you are using a internal version of PostgreSQL.

## Installation

1. The example file is almost entirely commented out. The only part that is not
   commented out is required for the successful operation of the code blocks
   that follow.

2. Based on the following description of the blocks of code included in the
   example, determine if you want to use any of the example file in your
   deployment. If you do, copy the example file and place it in your
   site-config directory. In the new file, uncomment the block or blocks you
   want to use by removing the number sign (#) and adding a space at the
   beginning of each line in the block. If there are two number signs, remove
   only the first. Make sure block comments are aligned with the yaml data
   structure.

3. Each block has information about its content. The variables in the block are
   set off by curly braces and spaces, such as {{ STORAGE-SIZE-IN-GB }}.
   Replace the entire variable string, including the braces, with the value
   you want to use.

4. After you have edited the file, add a reference to it in the transformer
block of the base kustomization.yaml file.

## Examples

The example file is located at
`sas-bases/examples/configure-postgres/internal/storage/postgres-storage-transformer.yaml`.
It includes content for configuring the following settings.

* Specify the PostgSQL PVC storage size for primary and standby (replica)
* Specify the storage class for archive, backrest, primary, and replica
* Specify the storage type for archive, backrest, primary, and replica
* Specify the access mode for archive, backrest, primary, and replica

## Additional Resources

For more information about using the example file, see the
[SAS Viya Deployment Guide](http://documentation.sas.com/?softwareId=mysas&softwareVersion=prod&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm).

For more information about pgo.yaml configuration, go
[here](https://access.crunchydata.com/documentation/postgres-operator/4.2.2/configuration/pgo-yaml-configuration/).