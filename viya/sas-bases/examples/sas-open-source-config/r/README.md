# Configure R for SAS Viya

## Overview

SAS Viya can use a customer-prepared environment consisting of an R
installation and any required packages stored on a Kubernetes
Persistent Volume. This readme describes how to make that volume
available to your deployment.

## Prerequisites

SAS Viya provides YAML files that the Kustomize tool uses to configure R. Before you use those files, perform the following tasks:

* Note the attributes of the volume where R and the associated packages are to be deployed. For example, for
  NFS, note the NFS server and directory. The "Additional Resources"
  section below contains links to more information about the various types
  of Persistent Volumes in Kubernetes.
* Install R and any necessary packages on the volume.
* In addition to the volume attributes, you will need the following information for later:
  * {{ R-MOUNTPATH }} - the path in which R is mounted (for example, /nfs/r-mount)
  * {{ R-HOMEDIR }} - the top-level directory of the R installation on that volume (for example, R-3.6.2)
  * {{ SAS-EXTLANG-SETTINGS-XML-FILE }} - configuration file for enabling Python and R integration in CAS. This is only needed if using R with either CMP or the EXTLANG package.
  * {{ SAS-EXT-LLP-R-PATH }} - list of directories to look for when searching for run-time shared libraries (similar to LD_LIBRARY_PATH)

## Installation

1. Copy the files in the `$deploy/sas-bases/examples/sas-open-source-config/r` directory
to the `$deploy/site-config/sas-open-source-config/r` directory. Create the target directory, if
it does not already exist.

2. The kustomization.yaml file defines all the necessary environment variables.
Replace all tags, such as {{ R-HOMEDIR }}, with what you gathered in
the "Prerequisites" step. Then, set the following parameters, according to the SAS products you will be using:
* DM_RHOME is used by the Open Source Code node in SAS Visual Data Mining
  and Machine Learning.
* SAS_EXTLANG_SETTINGS is used by applications that run Python and R code on
  Cloud Analytic Services (CAS). This includes PROC FCMP and the
  Time Series External Languages (EXTLANG) package. SAS_EXTLANG_SETTINGS
  should only be set in one example file; for example, if you set it in
  the Python example, you should not set it the R example.
  SAS_EXTLANG_SETTINGS should point to an XML file that is readable by
  all users. The path can be in the same volume that contains the R
  environment or in any other volume that is accessible to CAS. Refer
  to the documentation for the Time Series External Languages (EXTLANG)
  package for details on the expected XML schema.
* SAS_EXT_LLP_R is used when the base distribution or packages for open source
  software require additional run-time libraries that are not part of the shipped
  container image.

3. Attach storage to your SAS Viya deployment.
The r-transformer.yaml file uses PatchTransformers in kustomize
to attach the volume containing your R installation to SAS Viya.
Replace {{ VOLUME-ATTRIBUTES }} with the appropriate volume specification.
For example, when using an NFS mount, the {{ VOLUME-ATTRIBUTES }} tag should be
replaced with `nfs: {path: /vol/r-mount, server: myserver.sas.com}`
where `myserver.sas.com` is the NFS server and `/vol/r-mount` is the
NFS path you recorded in the Prerequisites.

The relevant code excerpt from r-transformer.yaml file before the change:
```yaml
patch: |-
  # Add R Volume
  - op: add
    path: /spec/template/spec/volumes/-
    value: { name: r-volume, {{ VOLUME-ATTRIBUTES }} }
  # Add mount path for R
  - op: add
    path: /template/spec/containers/0/volumeMounts/-
    value:
      name: r-volume
      mountPath: {{ R-MOUNTPATH }}
      readOnly: true
```

The relevant code excerpt from r-transformer.yaml file after the change:
```yaml
patch: |-
  # Add R Volume
  - op: add
    path: /spec/template/spec/volumes/-
    value: { name: r-volume, nfs: {path: /vol/r, server: myserver.sas.com} }
  # Add mount path for R
  - op: add
    path: /template/spec/containers/0/volumeMounts/-
    value:
      name: r-volume
      mountPath: /nfs/r-mount
      readOnly: true
```

4. Make the following changes to the base kustomization.yaml file in the $deploy directory.
* Add site-config/sas-open-source-config/r to the resources block.
* Add site-config/sas-open-source-config/r/r-transformer.yaml to the transformers block.

## Additional Resources

For more information about the SAS Viya deployment process, see the [SAS Viya Deployment Guide](http://documentation.sas.com/?softwareId=mysas&softwareVersion=prod&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm&locale=en).

Information about Persistent Volumes on Kubernetes is located [here](https://kubernetes.io/docs/concepts/storage/persistent-volumes/).

For details of attributes for different kinds of volumes, like NFS, hostPath, PVC and others, refer to
  [Kubernetes documentation](https://kubernetes.io/docs/concepts/storage/volumes/#types-of-volumes).

The XML schema for the file pointed to by {{ SAS-EXTLANG-SETTINGS-XML-FILE }} is described in the
  [EXTLANG documentation](http://documentation.sas.com/?cdcId=pgmsascdc&cdcVersion=v_001&docsetId=castsp&docsetTarget=castsp_extlang_sect002.htm&locale=en).