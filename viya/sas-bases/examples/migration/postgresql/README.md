---
category: migration
tocprty: 4
---

# Uncommon Migration Customizations

## Overview

This readme contains information for customizations potentially required for migrating to SAS Viya 4. These customizations are not used often.

## Configure New PostgreSQL Name

If you change the name of the PostgreSQL service during migration, you must map the new name to the old name. Edit $deploy/kustomization.yaml and add an entry to the restore_job_parameters configMap in configMapGenerator section. The entry uses the following format:

```
data-service-{{ NEW-SERVICE-NAME }}={{ OLD-SERVICE-NAME }}
```

In the following example, NEW-SERVICE-NAME is sas-crunchy-data-postgres, and OLD-SERVICE-HAME is postgres:

```yaml
configMapGenerator:
- name: sas-restore-job-parameters
  behavior: merge
  literals:
    ...
    - data-service-sas-crunchy-data-postgres=postgres
```

## Exclude Schemas During Migration

If you need to exclude some of the schemas during migration, edit $deploy/kustomization.yaml and add an entry to the restore_job_parameters configMap in configMapGenerator section. The entry uses the following format:

```
EXCLUDE_SCHEMAS={schema1, schema2,...}
```

In the following example, "dataprofiles" and "naturallanguageunderstanding" are schemas that will not be migrated.

```yaml
configMapGenerator:
- name: sas-restore-job-parameters
  behavior: merge
  literals:
    ...
    - EXCLUDE_SCHEMAS=dataprofiles,naturallanguageunderstanding
```

## Custom Database name

If the database name on the system you want to restore (the target system) does not match the database name on the system from where a backup has been taken (the source system), then you must provide the appropriate database name as part of the restore operation.

The database name is provided by using an environment variable, RESTORE_DATABASE_MAPPING, which should be specified in the restore job ConfigMap, sas-restore-job-parameters. Use the following format:

``` RESTORE_DATABASE_MAPPING=<source instance name>.<source database name>=<target instance name>.<target database name>```

For example, if the source system has the database name "SharedServices" and the target system database is named "TestDatabase", then the environment variable would look like this:

``` RESTORE_DATABASE_MAPPING=postgres.SharedServices=postgres.TestDatabase```

## Additional Resources

For more information about migration, see [SAS Viya Administration: Migration](https://documentation.sas.com/?softwareId=viyaadmin&softwareVersion=prod&docsetId=calmigration&docsetTarget=titlepage.htm).

**Note:** Ensure that the version indicated by the version selector for the document matches the version of your SAS Viya software.

## Enable Parallel Execution for the Restore Operation

You can set a jobs option that reduces the amount of time required to restore the SAS Infrastructure Data server. The time required to restore the database from backup is reduced by restoring the database objects over multiple parallel jobs. The optimal value for this option depends on the underlying hardware of the server, of the client, and of the network (for example, the number of CPU cores). Refer to the [--jobs](https://www.postgresql.org/docs/12/app-pgrestore.html "pg_restore documentation") parameter for more information about the parallel jobs. 

You can specify the number of parallel jobs using the following environment variable, which should be specified in the sas-restore-job-parameters config map.

`SAS_DATA_SERVER_RESTORE_PARALLEL_JOB_COUNT=<number-of-jobs>`

The following section, if not present, can be added to the kustomization.yaml file in your `$deploy` directory. If it is present, append the properties shown in this example in the `literals` section.

```yaml
configMapGenerator:
- name: sas-restore-job-parameters
behavior: merge
literals:
    - SAS_DATA_SERVER_RESTORE_PARALLEL_JOB_COUNT=<number-of-jobs>
```