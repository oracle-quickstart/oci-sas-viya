---
category: updateChecker
tocprty: 1
---

# Update Checker Cron Job

## Overview

The Update Checker cron job builds a report comparing the currently
deployed release with available releases in the upstream repository.
The report is written to the stdout of the launched job pod and
indicates when new content related to the deployment is available.
Unless you use the Update Checker job, your SAS Viya 4 deployment
does not have an automated way to receive indication of changes that
are available.

## Installation

To add the Update Checker cron job to your deployment,
add this overlay directory to the resources block of the
base kustomization.yaml.

Here is an example:

```yaml
...
resources:
- sas-bases/overlays/update-checker
```

After the base kustomization.yaml has been modified, build and apply
the manifest according to the instructions in [SAS Viya Deployment Guide](http://documentation.sas.com/?softwareId=mysas&softwareVersion=prod&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm&locale=en).

## Usage

The job runs weekly. To view the report:

1. Determine the full names of pods for the update checker:

   ```
   kubectl get pods | grep sas-update
   ```

   The results will look something like this:

   ```
   sas-update-checker-1592301600-q2scv 0/1 Completed 0 2d2h
   sas-update-checker-1592388000-pk7rw 0/1 Completed 0 26h
   sas-update-checker-1592474400-r7dd2 0/1 Completed 0 154m
   ```

2. Select the most recently created pod from the list and use it in the following command:

   ```
   kubectl logs -f sas-update-checker-[unique hash value]
   ```

   Using the example above, the command would look like this:

   ```
   kubectl logs -f sas-update-checker-1592474400-r7dd2
   ```
