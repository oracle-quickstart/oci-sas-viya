# Uncommon Restore Customizations

## Overview

This README file contains information about customizations that are potentially required for restoring SAS Viya from a backup. These customizations are not used often.

## Custom Database name

If the database name on the system you want to restore (the target system) does not match the database name on the system from where a backup has been taken (the source system), then you must provide the appropriate database name as part of the restore operation.

The database name is provided by using an environment variable, RESTORE_DATABASE_MAPPING, which should be specified in the restore job ConfigMap, sas-restore-job-parameters. Use the following format:

``` RESTORE_DATABASE_MAPPING=<source instance name>.<source database name>=<target instance name>.<target database name>```

For example, if the source system has the database name "SharedServices" and the target system database is named "TestDatabase", then the environment variable would look like this:

``` RESTORE_DATABASE_MAPPING=postgres.SharedServices=postgres.TestDatabase```

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