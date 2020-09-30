# Configuration for the sas-model-publish-kaniko PVC

## Overview
[Kaniko](https://github.com/GoogleContainerTools/kaniko) is a tool to build container images from a Dockerfile without depending on a Docker daemon. The Kaniko container can load the build context from cloud storage or a local directory, and then push the built image to the container registry for a specific destination.

The SAS Model Publish service uses the sas-model-publish-kaniko dedicated PersistentVolume Claim (PVC) as a workspace, which is shared with the Kaniko container. When a user publishes a model to a container destination, sas-model-publish creates a temporary folder (publish-xxxxxxxx) on the volume (/models/kaniko/), which is then mounted from the sas-model-publish-kaniko PVC in the start-up process.

The publishing process generates the following content:

- Context (Dockerfile and model ZIP file) in the /models/kaniko/publish-xxxxxxxx directory.
- AWS configuration in the  /models/kaniko/publish-xxxxxxxx-aws directory, if AWS is the publishing destination type.
- Docker configuration in the /models/kaniko/publish-xxxxxxxx-docker directory (Required by all three container destination types).

_**Note:** The "xxxxxxxx" part of the folder names is a system-generated alphanumeric string and is 8 characters in length._

The Model Publish service then loads a pod template from the sas-model-publish-kaniko-job-config (as defined in podtemplate.yaml) and dynamically constructs a job specification. The job specification helps mount the directories in the Kaniko container. The default pod template uses the official Kaniko image URL `gcr.io/kaniko-project/executor:latest`. Users can replace this image URL in the pod template, if the user wants to host the Kaniko image in a different container registry or use a Kaniko debug image.

The Kaniko container is started after a batch job is executed. The Model Publish service checks the job status every 30 seconds. The job times out after 30 minutes, if it has not completed.

The Model Publish service deletes the job and the temporary directories after the job has completed successfully, completed with errors, or has timed out.

## Files

In order for the Model Publish service to successfully publish a model to a container destination, the user must prepare and adjust the following files that are located in the `$deploy/sas-bases/examples/sas-model-publish` directory:

**storage.yaml**

  defines a PVC for the Kaniko workspace.

**podtemplate.yaml**

  defines a pod template for the batch job that launches the Kaniko container.

The following file is located in the `$deploy/sas-bases/overlays/sas-model-publish/` directory and does not need to be modified:

**transformers.yaml**

  adds the sas-model-publish-kaniko PVC to the sas-model-publish deployment object.

## Installation

1. Copy the files in the `$deploy/sas-bases/examples/sas-model-publish` directory to the `$deploy/site-config/sas-model-publish` directory. Create the target directory, if it does not already exist.
2. Modify the parameters in the podtemplate.yaml file, if you need to implement customized requirements, such as the location of Kaniko image.
3. Modify the parameters in storage.yaml. For more information about PersistentVolume Claims (PVCs), see [Persistent Volume Claims on Kubernetes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims).
* Replace {{ STORAGE-CAPACITY }} with the amount of storage required.
* Replace {{ STORAGE-CLASS-NAME }} with the appropriate storage class from the cloud provider that supports ReadWriteMany access mode.
4. Make the following changes to the base kustomization.yaml file in the $deploy directory.
* Add site-config/sas-model-publish to the resources block.
* Add sas-bases/overlays/sas-model-publish/transformers.yaml to the transformers block.
5. Use the deployment commands described in [SAS Viya Deployment Guide](http://documentation.sas.com/?softwareId=mysas&softwareVersion=prod&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm) to apply the new settings.