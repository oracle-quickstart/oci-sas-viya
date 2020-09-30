# Configure Python for SAS Viya

## Overview

SAS Viya can use a customer-prepared environment consisting of a Python
installation and any required packages stored on a Kubernetes
Persistent Volume. This readme describes how to make that volume
available to your deployment.

## Prerequisites

SAS Viya provides YAML files that the Kustomize tool uses to configure Python. Before you use those files, perform the following tasks:

* Note the attributes of the volume where Python and the associated packages are to be deployed. For example, for
  NFS, note the NFS server and directory. The "Additional Resources"
  section below contains links to more information about the various types
  of Persistent Volumes in Kubernetes.
* Install Python and any necessary packages on the volume.
* In addition to the volume attributes, you will need the following information for later:
  * {{ PYTHON-EXECUTABLE }} - the name of the Python executable file (for example, python or python3.8)
  * {{ PYTHON-EXE-DIR }} - the directory (relative to the mount) containing the executable (for example, /bin)
  * {{ SAS-EXTLANG-SETTINGS-XML-FILE }} - configuration file for enabling Python and R integration in CAS. This is only required if you are using Python with CMP or the EXTLANG package.
  * {{ SAS-EXT-LLP-PYTHON-PATH }} - list of directories to look for when searching for run-time shared libraries (similar to LD_LIBRARY_PATH)

## Installation

1. Copy the files in the `$deploy/sas-bases/examples/sas-open-source-config/python` directory
to the `$deploy/site-config/sas-open-source-config/python` directory. Create the target directory, if
it does not already exist.

2. The kustomization.yaml file defines all the necessary environment variables.
Replace all tags, such as {{ PYTHON-EXE-DIR }}, with what you gathered in
the "Prerequisites" step. Then, set the following parameters, according to the SAS products you will be using:
* MAS_PYPATH and MAS_M2PATH are used by the SAS Micro Analytic Service.
* DM_PYTHONHOME is used by the Open Source Code node in SAS Visual Data Mining and
  Machine Learning. The code in Open Source Code node runs by executing
  `$DM_PYTHONHOME/python <editor_code.py>`
  The above call expects an executable named "python" in {{ PYTHON-EXE-DIR }};
  if that is not available, consider creating a symbolic link "python" that
  points to {{ PYTHON-EXECUTABLE }}.
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
* SAS_EXT_LLP_PYTHON is used when the base distribution or packages for open source
  software require additional run-time libraries that are not part of the shipped
  container image.

***Note:*** Any environment variables that you define in this example
will be set on all pods, although they may not have an effect.
For example, setting MAS_PYPATH will not affect the Python executable
used by the EXTLANG package. That executable is set in the
SAS_EXTLANG_SETTINGS file. However, if you define $MAS_PYPATH you can then
use it in the SAS_EXTLANG_SETTINGS file. For example,
```<LANGUAGE name="PYTHON3" interpreter="$MAS_PYPATH"></LANGUAGE>```

3. Attach storage to your SAS Viya deployment.
The python-transformer.yaml file uses PatchTransformers in Kustomize
to attach the volume containing your Python installation to SAS Viya.
Replace {{ VOLUME-ATTRIBUTES }} with the appropriate volume specification.
For example, when using an NFS mount, the {{ VOLUME-ATTRIBUTES }} tag should be
replaced with `nfs: {path: /vol/python, server: myserver.sas.com}`
where `myserver.sas.com` is the NFS server and `/vol/python` is the
NFS path you recorded in the Prerequisites step.

The relevant code excerpt from python-transformer.yaml file before the change:
```yaml
patch: |-
  # Add Python Volume
  - op: add
    path: /spec/template/spec/volumes/-
    value: { name: python-volume, {{ VOLUME-ATTRIBUTES }} }
  # Add mount path for Python
  - op: add
    path: /template/spec/containers/0/volumeMounts/-
    value:
      name: python-volume
    mountPath: {{ PY-MOUNTPATH }}
      readOnly: true
```

The relevant code excerpt from python-transformer.yaml file after the change:
```yaml
patch: |-
  # Add Python Volume
  - op: add
    path: /spec/template/spec/volumes/-
    value: { name: python-volume, nfs: {path: /vol/python, server: myserver.sas.com} }
  # Add mount path for Python
  - op: add
    path: /template/spec/containers/0/volumeMounts/-
    value:
      name: python-volume
      mountPath: /nfs/python
      readOnly: true
```

4. Make the following changes to the base kustomization.yaml file in the $deploy directory.
* Add site-config/sas-open-source-config/python to the resources block.
* Add site-config/sas-open-source-config/python/python-transformer.yaml to the transformers block.

## Additional Resources

For more information about the SAS Viya deployment process, see the [SAS Viya Deployment Guide](http://documentation.sas.com/?softwareId=mysas&softwareVersion=prod&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm&locale=en).

Information about Persistent Volumes on Kubernetes is located [here](https://kubernetes.io/docs/concepts/storage/persistent-volumes/).

For details of attributes for different kinds of volumes, like NFS, hostPath, PVC and others, refer to
  [Kubernetes documentation](https://kubernetes.io/docs/concepts/storage/volumes/#types-of-volumes).

The XML schema for the file pointed to by {{ SAS-EXTLANG-SETTINGS-XML-FILE }} is described in the
  [EXTLANG documentation](http://documentation.sas.com/?cdcId=pgmsascdc&cdcVersion=v_001&docsetId=castsp&docsetTarget=castsp_extlang_sect002.htm&locale=en).