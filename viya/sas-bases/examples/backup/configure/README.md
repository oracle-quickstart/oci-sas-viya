# Configuration Settings for SAS Viya Backup

## Overview

This readme describes how to revise and apply the settings available for
configuring backup jobs.

## Change storage size for `sas-common-backup-data` persistent volume claim

## Instructions

1.  Copy the file `$deploy/sas-bases/examples/backup/configure/sas-common-backup-data-storage-size-transformer.yaml`
to a location of your choice under `$deploy/site-config`, such as `$deploy/site-config/backup`.

2. Follow the instructions in the copied sas-common-backup-data-storage-size-transformer.yaml
file to change the values in that file as necessary.

3. Add the full path of the copied file to the transformers block of the base
kustomization.yaml file (`$deploy/kustomization.yaml`). For example, if you
moved the file to `$deploy/site-config/backup`, you would modify the
base kustomization.yaml file like this:

```
...
transformers:
...
- site-config/backup/sas-common-backup-data-storage-size-transformer.yaml
...
```