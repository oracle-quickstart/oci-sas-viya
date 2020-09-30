# SAS Quality Knowledge Base Maintenance Scripts

## Overview

This readme describes the scripts available for maintaining Quality Knowledge Base (QKB) content in SAS Viya.  QKBs support the SAS Data Quality product.

These scripts are intended for ad hoc use after deployment. They generate YAML that is suitable for consumption by kubectl. The YAML creates Kubernetes Job objects to perform the specific task designated by the script name.  After these jobs have finished running, they can be removed.

## Script Details

### `containerize-qkb.sh`

#### Usage

    containerize-qkb.sh "NAME" PATH REPO[:TAG]

#### Description

This script runs Docker to create a specially formatted container that allows the QKB to be imported into SAS Viya running in Kubernetes.

For the NAME argument, provide the name by which the QKB will be surfaced in SAS Viya.  It may include spaces, but must be enclosed with quotation marks.

The PATH argument should be the location on disk where the QKB QARC file is located.

The REPO argument specifies the repository to assign to the Docker container that will be created.  TAG may be specified after a colon in standard Docker notation.

After the script runs, a new Docker container with the specified tag is created in the local Docker registry.

#### Example

    $ bash containerize-qkb.sh "My Own QKB" /tmp/myqkb.qarc registry.mycompany.com/myownqkb:v1
    Setting up staging area...
    Generating Dockerfile...
    Running docker...
    Docker container generated successfully.
    
    REPOSITORY                      TAG IMAGE ID     CREATED      SIZE
    registry.mycompany.com/myownqkb v1  8dfb63e527c8 1 second ago 945.3MB

After the script completes, information about the new container is output, as shown above.  If the local docker registry is not accessible to your Kubernetes cluster, you should then push the container to one that is.

    $ docker push registry.mycompany.com/myownqkb:v1
    The push refers to repository [registry.mycompany.com/myownqkb]
    f2409fb2f83e: Pushed
    076d9dcc6e6a: Mounted from myqkb-image1
    ce30860818b8: Mounted from myqkb-image1
    dfadf160ceab: Mounted from myqkb-image1
    v2: digest: sha256:b9802cff2f81dba87e7bb92355f2eb0fd14f91353574233c4d8f662a0b424961 size: 1360

---

### `deploy-qkb.sh`

#### Usage

    deploy-qkb.sh REPO[:TAG]

#### Description

This script deploys a containerized QKB into SAS Viya.  The REPO argument specifies a Docker repo (and, optionally, tag) from which to pull the container.  Note that this script does not make any changes to your Kubernetes configuration directly; instead it generates a Kubernetes Job that can then be piped to the kubectl command.

While SAS Viya persists all deployed QKBs in the sas-quality-knowledge-base PVC, we recommend following the GitOps pattern of storing the generated YAML file in version control, under your $deploy/site-config directory.   Doing so allows you to easily re-deploy the same QKB again later, should the PVC be deleted.

#### Examples

Generate a Kubernetes Job to deploy a QKB, and run it immediately:

    bash deploy-qkb.sh registry.mycompany.com/myownqkb:v1 | kubectl apply -n name-of-namespace -f -

Generate a Kubernetes Job to deploy a QKB, and write it into your site's overlays directory:

    bash deploy-qkb.sh registry.mycompany.com/myownqkb:v1 >> $deploy/site-config/data-quality/custom-qkbs.yaml

This command appends the job configuration for the new QKB to the file called "custom-qkbs.yaml".  This is a convenient place to store all custom QKB jobs, and is suitable for inclusion into the SAS Viya base kustomization.yaml file as a resource overlay.  

If you do not yet have a $deploy/site-config/data-quality directory, you can create and initialize it as follows:

    mkdir -p $deploy/site-config/data-quality
    cp $deploy/sas-bases/overlays/data-quality/* $deploy/site-config/data-quality

To attach custom-qkbs.yaml to your SAS Viya configuration, edit your base kustomization.yaml file, and find or create the "resources:" section.  Under that section, add the following line:

    - site-config/data-quality

You can re-apply these kustomizations to bring the new QKB into the SAS Viya system.

---

### `list-qkbs.sh`

#### Usage

    list-qkbs.sh

#### Description

A parameter-less script that generates Kubernetes Job YAML to list the names of all QKBs available on sas-quality-knowledge-bases volume.  Output is sent to the log for the pod created by the job.

#### Examples

    $ bash list-qkbs.sh | kubectl apply -n name-of-namespace -f -
    job.batch/sas-quality-knowledge-base-list-job-ifvw01lr created

    $ kubectl -n name-of-namespace logs job.batch/sas-quality-knowledge-base-list-job-ifvw01lr
    QKB CI 31
    My Own QKB

    $ kubectl -n name-of-namespace delete job.batch/sas-quality-knowledge-base-list-job-ifvw01lr
    job.batch "sas-quality-knowledge-base-list-job-ifvw01lr" deleted

If a QKB is in the process of being deployed, or was aborted for some reason, you may see the string "(incomplete)" after that QKB's name:

    $ kubectl -n name-of-namespace logs job.batch/sas-quality-knowledge-base-list-job-ifvw01lr
    QKB CI 31
    My Own QKB  (incomplete)

---

### `remove-qkb.sh`

#### Usage

    remove-qkb.sh NAME

#### Description

Generates Kubernetes Job YAML that removes a QKB from the sas-quality-knowledge-bases volume.  The QKB to remove is specified by NAME, which is returned by `list-qkbs.sh`.  Any errors or other output is written to the associated pod's log and can be viewed using the `kubectl logs` command.

#### Examples:

    $ bash remove-qkb.sh "My Own QKB" | kubectl apply -n name-of-namespace -f -
    job.batch/sas-quality-knowledge-base-remove-job-zbl4sxmq created

    $ kubectl logs -n name-of-namespace job.batch/sas-quality-knowledge-base-remove-job-zbl4sxmq
    Reference data content "My Own QKB" was removed.

    $ kubectl delete -n name-of-namespace job.batch/sas-quality-knowledge-base-remove-job-zbl4sxmq
    job.batch "sas-quality-knowledge-base-remove-job-zbl4sxmq" deleted

---

## Additional Resources

For more information about the QKB, see the SAS Data Quality documentation.