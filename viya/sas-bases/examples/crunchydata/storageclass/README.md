# Set the StorageClass for CrunchyData PostgreSQL

## Overview

This directory contains files to customize your SAS Viya 4 PostgreSQL to use
your own StorageClass.

**Note:** If you are using an external instance of PostgreSQL, you can ignore 
the instructions in this readme.

## Instructions

1. Copy the file `$deploy/sas-bases/examples/crunchydata/storageclass/storage-class-transformer.yaml` 
   to `$deploy/site-config/examples/crunchydata/storageclass/storage-class-transformer.yaml`.

2. The file is using trident as the StorageClass. If you are not using trident
   as your StorageClass, replace each use of "trident" with the name of your
   StorageClass. If you are using trident as your StorageClass, do not make any
   changes. Save the file.

3. In the base kustomization.yaml file in the $deploy directory, add a reference
   to the storage-class-transformer.yaml file in the transformers block:

   ```
   ...
   transformers:
   ...
   - site-config/examples/crunchydata/storageclass/storage-class-transformer.yaml
   ...
   ```

After the base kustomization.yaml file is modified, deploy the software using 
the commands described in
[SAS Viya Deployment Guide](http://documentation.sas.com/?softwareId=mysas&softwareVersion=prod&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm).).

## Additional Resources

For information about internal and external instances of PostgreSQL, see
[Internal versus External PostgreSQL Instances](http://documentation.sas.com/?softwareId=mysas&softwareVersion=prod&docsetId=itopssr&docsetTarget=n1rbbuql9epqa0n1pg3bvfx3dmvc.htm&locale=en#n1s8cr44xdfny1n1dd8w46828xce).