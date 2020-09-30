# Configuring Kerberos Single Sign-On for SAS Viya 4

This README describes the steps necessary to configure your SAS Viya 4 deployment for single sign-on
using Kerberos.

## Prerequisites

Before you start the deployment, obtain the Kerberos configuration file and keytab for the HTTP
service account. Make sure you have tested the keytab before proceeding with the installation.

## Installation

1. Copy the files in the `$deploy/sas-bases/examples/kerberos/http` directory to the `$deploy/site-config/kerberos/http` directory. Create the target directory, if it does not already exist.

2. Copy your Kerberos keytab and configuration files into the `$deploy/site-config/kerberos/http` directory, naming them `keytab` and `krb5.conf` respectively.

3. Modify the parameters in `$deploy/site-config/kerberos/http/configmaps.yaml`.
* Replace {{ PRINCIPAL-NAME-IN-KEYTAB }} with the name of the principal as it appears in the keytab.
* Replace {{ SPN }} with the name of the SPN. This should have a format of `HTTP/<hostname>` and may be the same as the principal name in the keytab.

4. Make the following changes to the base kustomization.yaml file in the $deploy directory.
* Add site-config/kerberos/http to the resources block.
* Add sas-bases/overlays/kerberos/http/transformers.yaml to the transformers block.

5. Use the deployment commands described in [SAS Viya Deployment Guide](http://documentation.sas.com/?softwareId=mysas&softwareVersion=prod&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm) to apply the new settings.