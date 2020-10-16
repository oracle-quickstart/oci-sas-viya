---
category: backupRestore
tocprty: 2
---

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

## Change Backup/Scan Job Timeout

If you need to change the backup job timeout value, add an entry to the sas-backup-job-parameters configMap in the configMapGenerator block of the base kustomization.yaml file. The entry uses the following format, where {{ TIMEOUT-IN-MINUTES }} is an integer

```yaml
configMapGenerator:
- name: sas-backup-job-parameters
  behavior: merge
  literals:
  - JOB_TIME_OUT={{ TIMEOUT-IN-MINUTES }}
```

If the sas-backup-job-parameters configMap is already present in the base kustomization.yaml file, you should add the last line only. If the configMap is not present, add the entire example.

## Change Backup Retention Period

If you need to change the backup retention period, add an entry to the sas-backup-job-parameters configMap in the configMapGenerator block of the base kustomization.yaml file. The entry uses the following format, where {{ RETENTION-PERIOD-IN-DAYS }} is an integer.

```yaml
configMapGenerator:
- name: sas-backup-job-parameters
  behavior: merge
  literals:
  - RETENTION_PERIOD={{ RETENTION-PERIOD-IN-DAYS }}
```
If the sas-backup-job-parameters configMap is already present in the base kustomization.yaml file, you should add the last line only. If the configMap is not present, add the entire example.

## Back Up Additional Consul Properties

If you want to back up additional consul properties, keys can be added to the sas-backup-agent-parameters configMap. To add keys, add a data block to the configMap. If the sas-backup-agent-parameters configMap is already included in your base kustomization.yaml file, you should add the last line only. If the configMap isn't included, add the entire example.

```yaml
configMapGenerator:
- name: sas-backup-agent-parameters
  behavior: merge
  literals:
  - BACKUP_ADDITIONAL_GENERIC_PROPERTIES={{ CONSUL-KEY-1 }},{{ CONSUL-KEY-2 }}
```

 The {{ CONSUL-KEY }} variables should be a comma-separated list of properties to be backed up, such as `config/files/sas.files/maxFileSize` or `config/files/sas.files/blockedTypes`.