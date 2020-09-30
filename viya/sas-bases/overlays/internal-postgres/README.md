# Set Up an Internal PostgreSQL Instance for SAS Viya

By default, SAS Viya will not add a PostgreSQL instance to the Kubernetes
deployment. SAS Viya includes two options for your PostgreSQL server: an
internal instance provided by SAS or an external PostgreSQL that you want SAS
to use.

This readme describes the files used to customize your SAS Viya deployment to
use the internal PostgreSQL provided by SAS. The internal PostgreSQL instance is
created using the
[PostgreSQL Operator and Containers](https://github.com/crunchydata)
provided by [Crunchy Data](https://www.crunchydata.com/)

**Note:** If you want to use an external instance of PostgreSQL, you should
refer to the readme file located at
`$deploy/sas-bases/overlays/external-postgres/README.md`.

## Instructions
In order to use the internal PostgreSQL instance, you must customize your
deployment to point to the required overlay.

1. Go to the base kustomization.yaml file (`$deploy/kustomization.yaml`). In the
   resources block of that file, add the following content, including adding
   the block if it does not already exist.

   ```yaml
   resources:
   - sas-bases/overlays/internal-postgres
   ```

2. Then add the following content to the transformers block.

   ```yaml
   transformers:
   - sas-bases/overlays/internal-postgres/internal-postgres-transformer.yaml
   ```

   **Note:** The initial kustomization.yaml file described in
   [SAS Viya Deployment Guide](http://documentation.sas.com/?softwareId=mysas&softwareVersion=prod&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm&locale=en)
   includes the content necessary to deploy an internal PostgreSQL instance.
   Also, an example of a completed base kustomization.yaml file for an
   internal PostgreSQL instance is located at
   `$deploy/sas-bases/examples/configure-postgres/internal-kustomization.yaml`.

3. After you revise the base kustomization.yaml file, continue your SAS Viya
   Deployment as documented in
   [SAS Viya Deployment Guide](http://documentation.sas.com/?softwareId=mysas&softwareVersion=prod&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm&locale=en).

## Upgrade the PostgreSQL Operator and PostgreSQL Cluster

### Overview

If you are updating your software, you must perform the following steps.
If you are performing a new deployment of your software, these steps can be
safely ignored.

The directory
`$deploy/sas-bases/overlays/internal-postgres/postgres-cluster-update`
contains files to stage your existing SAS Viya 4 deployment for an internal
PostgreSQL server update and internal PostgreSQL Operator update.

### Instructions

**Note:** These instructions only apply to the internal instance of PostgreSQL
server. If you are using an external instance of PostgreSQL, do not perform
any of these steps.

The following steps need to be performed before applying your manifest for the
new version of SAS Viya. Replace the entire variable
`{{ KUBERNETES-NAMESPACE }}`, including the braces, with the Kubernetes
namespace used for SAS Viya.

1. As an administrator with namespace permissions, run the following
   `kubectl apply` command. The command instructs the internal PostgreSQL
   Operator to terminate the existing internal PostgreSQL cluster.

   ```bash
   kubectl apply -f sas-bases/overlays/internal-postgres/postgres-cluster-update/pgtask-rmdata.yaml -n {{ KUBERNETES-NAMESPACE }}
   ```

2. As an administrator with namespace permissions, run the following command.
   The command ensures that internal PostgreSQL pods are in the terminating 
   state.

   ```bash
   kubectl get po -l  pg-cluster=sas-crunchy-data-postgres -n {{ KUBERNETES-NAMESPACE }}
   ```

   If the pods are in a Running state, repeat this command until they are in a
   Terminating state.

3. As an administrator with namespace permissions, scale down the existing
   internal PostgreSQL Operator deployment:

   ```bash
   kubectl scale deployment --replicas=0 sas-crunchy-data-postgres-operator -n {{ KUBERNETES-NAMESPACE }}
   ```

4. As an administrator with namespace permissions, run the following command.
   The command ensures that there are no pods running the internal PosgreSQL
   operator.

   ```bash
   kubectl get po -l vendor=crunchydata,pgrmdata!=true,name!=sas-crunchy-data-pgadmin -n {{ KUBERNETES-NAMESPACE }}
   ```

   This is the expected output for this command:

   ```
   No resources found in < KUBERNETES-NAMESPACE > namespace
   ```

   Do not continue with your SAS Viya software update until the command
   indicates that no resources have been found.

   For more information on SAS Viya software updates, see
   [Updating Your SAS Viya Software](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=v_002&docsetId=k8sag&docsetTarget=p0hm2t63wm8qcqn1iqs6y8vw8y81.htm&locale=en)

## Additional Resources

For more information about the difference between the internal and external
instance of PostgreSQL, see
[SAS Infrastructure Data Server Requirements](http://documentation.sas.com/?softwareId=mysas&softwareVersion=prod&docsetId=itopssr&docsetTarget=n1rbbuql9epqa0n1pg3bvfx3dmvc.htm).