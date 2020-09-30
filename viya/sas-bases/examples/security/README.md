---
category: security
tocprty: 1
---

# Configure Network Security and Encryption Using SAS Security Certificate Framework
## Overview
The SAS Security Certificate Framework is a collection of software applications that integrate the security requirements of your SAS applications and your Kubernetes security infrastructure.

## Pre-requisites

cert-manager
*  Version 0.11 or later
*  A cert-manager issuer named sas-viya-issuer must exist prior to deploying Viya

A SAS Viya deployment cannot be performed until this cert-manager issuer exists. An example deploy file with the necessary issuer is included in your deployment assets.

Follow this example to create the issuers.  Replace the text "Namespace-of-My-Viya-Deployment" with the namespace that will contain SAS Viya.

```text
kubectl create -n Namespace-of-My-Viya-Deployment -f /My_SAS_Deployment_Assets_Directory/sas-bases-examples/security/sas-viya-issuer.yaml
```

To verify if the issuers exist, issue the following command.  It will display cert-manager issuers in the namespace listed . Confirm that you see an issuer named "sas-viya-issuer" listed.

```text
> kubectl -n "Namespace-of-My-Viya-Deployment" get issuers.cert-manager.io
NAME                          AGE
sas-viya-issuer               2d23h
sas-viya-selfsigning-issuer   2d23h
```

## Installation

The following customizations are provided to enable TLS for network communication involving your SAS Viya applications.  They require information that is specific to your environment, such as the host name of your Ingress controller, the path to files containing your Ingress x.509 certificates, and optionally your site's CA certificate(s).

These instructions assume that you created a $deploy/site-config directory as suggested in [SAS Viya Deployment Guide](http://documentation.sas.com/?softwareId=mysas&softwareVersion=prod&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm). We further suggest that you create sub-directories under site-config for the different categories of files that are required.

The following is a conceptual directory structure that illustrates the different types of files that will be used during your deployment.

```text
   $deploy/
   ├── site-config/
   │   └── security/
   │      ├── cacerts/
   │      │   ├── my_CA_Certs.pem (optional file(s) containing a set of CA certificates)
   │      │   └── my_other CA_certs.pem (multiple CA certificate files are allowed)
   │      ├── my_ingress_cert.crt
   │      ├── my_ingress_cert.key
   │      ├── customer-provided-ca-certificates.yaml
   │      ├── customer-provided-ingress-certificate.yaml
   │      └── cert-manager-provided-ingress-certificate.yaml
   ├── kustomization.yaml
   ├── sas-bases
   │      ├── base
   │      ├── examples
   │      ├── overlays
   │      └── more files and directories
   └── more files and directories
```

## TLS for SAS Viya Applications

SAS Viya supports three “modes” of TLS configuration: “Front-door" TLS, “Full-stack" TLS (Front-door and Back-end), and “No TLS”.
Think of your Kubernetes cluster as a house.  The pods running in the cluster are the different rooms and rooms are separated from one another by walls with doors.

Most servers in a SAS Viya deployment are only intended to accept connections from servers that reside within the same cluster.  These are back-end services.  The network traffic between these services remains entirely within the house.  The only doors this traffic passes through are interior doors.  These services only communicate with other services that also reside within the house.
Some servers within the SAS Viya deployment accept connections from clients and servers that reside outside the cluster.  For network traffic to reach its destination, this network traffic must travel through the “Front-door” of the house in order to reach its intended destination in the intended pod in one of rooms.

One way to deploy your software is with the belief that it is safe to leave the network traffic inside the cluster unencrypted since the house’s exterior walls can provide a safe perimeter.  Network traffic that remains entirely within this safe perimeter, within the cluster, need not be encrypted.  Only traffic that travels outside the safe confines of the house needs to be encrypted.  In this case, you would configure SAS Viya to only encrypt network traffic that will travel outside the house’s front door. Thus the name, “Front-door” TLS.

Another theory is that all traffic, whether interior to the house or outside, needs to be encrypted.  Hence, “Front-door and Back-end” TLS.

The servers that are intended to accept connections from outside the cluster include the NGINX Ingress controller, which routes traffic to all web applications such as SASDrive and SASStudio, and to SAS/CAS and SAS/CONNECT.  Think of SAS Viya as a triplex with three front doors:  NGINX, CAS and SAS/CONNECT.   All three front doors allow access to the same interior rooms (the back-end services).

If you configure SAS Viya to secure network traffic with TLS, those clients and servers that are outside the cluster will be required to trust the certificates used to secure the SAS Viya servers.  For this reason, you may want to configure those servers that accept connections which pass through the front door with your own certificates, which are already trusted by your organization’s infrastructure. The servers that only accept traffic from within the cluster and are configured by SAS can use certificates that are generated by the SAS Viya deployment itself.

### NGINX TLS (used in both Front-door and Full-stack TLS modes)

#### Certificates for the NGINX Controller

The NGINX controller is a Front-door server: it accepts connections that originate outside the cluster.  TLS connections can be secured by the NGINX process using a certificate and key.

You can provide your own certificate and key files to secure NGINX (likely because you obtained them from your organization’s IT department) or these files can be auto-generated by cert-manager.  Depending on the source of cert/key files, the configuration steps are different.  Choose from the two methods below based on the source of your NGINX cert/key files, then follow the steps in the corresponding section.

##### NGINX Certificate and Key Files Provided by Customer IT

Use this method if you have your own certificates and want to use them to secure connections to nginx.  This is desirable if you have "site signed certificates", that is, certificates with a root CA that is already widely distributed throughout your site.

It is required that the entire chain of trust for the NGINX Ingress certificate be provided to the deployment. This ensures that products that need to communicate via the Ingress will verify the certificate that NGINX presents.

This can be achieved in two ways:
* Place the entire chain in the Ingress secret. This can be spread between the tls.crt field and the ca.crt field. NGINX will only present the portion of the chain that is present in the tls.crt field.
* Place the Ingress certificate in the Ingress secret and place the rest of the chain in the config map for additional CA certificates. Follow the directions in the `Optional CA Certificates` to do so.

This method creates a Kubernetes secret containing your certificate and key.  This secret will be used during the SAS deployment whenever Ingress objects are created.  An annotated example of the code to create this secret is provided in the following kustomization file: `sas-bases/examples/security/customer-provided-ingress-certificate.yaml`. The example assumes you decide to provide your own certificates for the Ingress controller.

```text
cd $deploy
cp examples/security/customer-provided-ingress-certificate.yaml site-config/security
vi site-config/security/customer-provided-ingress-certificate.yaml

```

When your edits are in place, add the path to this file to the generators block of your $deploy/kustomization.yaml file.

```yaml
generators:
- site-config/security/customer-provided-ingress-certificate.yaml # configures Ingress to use a secret which contains customer provided certificate and key
```

##### NGINX Ingress Certificates Auto-Generated by cert-manager

If you do not have specific certs to use for the NGINX Ingress controller, SAS can generate them using cert-manager. As noted above, cert-manager is a pre-requisite and can be configured to have an issuer certificate of your choosing.  For example, it can be configured to generate a unique root CA at the time of deployment.

Follow these instructions to use cert-manager to generate the certificate used by the NGINX Ingress controller.

Add sas-bases/examples/security/cert-manager-provided-ingress-certificate.yaml to the transformers block of your base kustomization.yaml file:

```yaml
transformers:
- site-config/security/cert-manager-provided-ingress-certificate.yaml # causes cert-manager to generate ingress cert and store it in secret
```

Include only one of these two transformers.  If you include both of these files in your kustomization.yaml, errors will result.
Once you have chosen the desired method of providing the Ingress certificate and key, copy the corresponding kustomization file to your $deploy/site-config directory.  Edit the file to provide your site-specific information.  Instructions for editing this file are provided as comments in the file.

#### Resources and Transformers to Enable NGINX TLS

In addition to the file that specifies the source of certificates, you should also include these resources which provide security infrastructure in both the resources and transformers blocks of your base kustomization.yaml file as follows:

```yaml
resources:
- sas-bases/overlays/network/ingress/security # configure ingress to use TLS
```

**IMPORTANT:**  The ingress-tls-transformers.yaml line MUST be added before the line that lists the required transformers.  This line: "- sas-bases/overlays/required/transformers.yaml" should be last in the transformers" section.

```yaml
transformers:
- sas-bases/overlays/network/ingress/security/transformers/ingress-tls-transformers.yaml # configure Ingress to use TLS
```

### Enable TLS for SAS Front-Door Servers: CAS and SAS/CONNECT

**Note:** NGINX TLS is a pre-requisite.

CAS and SAS/CONNECT are Front-door servers because they accept connections from outside the cluster and handle network traffic that travels outside the perimeter of the cluster. To configure SAS Viya for Front-door TLS mode, add these transformers to your kustomization.yaml.  They configure CAS and SAS/CONNECT to encrypt network traffic.

**IMPORTANT:**
* Do not add these transformers if you intend to configure for Full-stack TLS mode (see below).
* These lines must come before the line that lists the required transformers, i.e., "- sas-bases/overlays/required/transformers.yaml"`

```yaml
transformers:
- sas-bases/overlays/network/ingress/security/transformers/cas-connect-tls-transformers.yaml # transformers to build trust stores for all services and enable backend TLS for CAS.
- sas-bases/overlays/required/transformers.yaml # This line is provided as a location reference, it should appear only once and not be duplicated.
```
### Full-Stack TLS Mode

**Note:** NGINX TLS is a pre-requisite.

To encrypt network traffic within the cluster, all servers must be configured to use TLS for all network connections.  NGINX must re-encrypted traffic before forwarding it to the "Back-end" SAS applications and SAS servers must use TLS when communicating directly with one another.  While this increases latency and increases CPU utilization, unless you do this, network traffic within your cluster will not be encrypted. To configure all servers to use TLS, include these resources in the `transformers:` section of your kustomization.yaml file.

**Important:** These lines must come before the line that lists the required transformers, ("- sas-bases/overlays/required/transformers.yaml").

Include these customizations in the transformers block of the base kustomization.yaml file:

```yaml
transformers:
- sas-bases/overlays/network/ingress/security/transformers/product-tls-transformers.yaml # adds the tls enablement data bits to selected product DUs
- sas-bases/overlays/network/ingress/security/transformers/backend-tls-transformers.yaml # transformers to support TLS for backend servers
- sas-bases/overlays/required/transformers.yaml # This line is provided as a location reference, it should appear only once and not be duplicated.
```
## Customer-Provided Optional CA Certificates

If you want to provide your own CA certificates to your SAS Viya software so that SAS can securely communicate with your IT infrastructure (LDAP server, internal web sites, or other infrastructure), follow these steps to provide your CA certificates to the SAS Viya deployment. The certificate files must be in pem format, and the path to the files should be relative to the directory that contains the kustomization.yaml file.

Since you may have to maintain several files containing CA certificates and these will need to be updated over time, it may be convenient to create a separate directory for these files as illustrated in the directory structure example above.

Place your CA certificate files in the `site-config/security/cacerts directory`. Copy the file `$deploy/examples/security/customer-provided-ca-certificates.yaml` into your `$deploy/site-config/security directory`.

Edit the `site-config/security/customer-provided-ca-certificates.yaml` file and enter the required information.  Instructions for editing this file are provided as comments in the file.

Here is an example:

```text
export deploy=~/deploy
cd $deploy
mkdir -p site-config/security/cacerts
#
# the following line assumes that your CA Certificates are in a file named /tmp/my_ca_certificates.pem
#
cp /tmp/my_ca_certificates.pem site-config/security/cacerts
cp examples/security/customer-provided-ca-certificates.yaml site-config/security
vi site-config/security/customer-provided-ca-certificates.yaml
```

When  your edits are in place, add the path to this file to the generators block of your `$deploy/kustomization.yaml` file. Here is an example:

```yaml
generators:
- site-config/security/customer-provided-ca-certificates.yaml # generates a configmap that contains CA Certificates
```

Add this overlay to the overlays block of the same file:

```yaml
resources:
- sas-bases/overlays/network/ingress/security #  includes customer provided CA certificates in trust bundles
```

## Trust Bundle Security Configuration When “No TLS” Mode Is Used

**IMPORTANT:** Do not add either of these transformers if you have configured Front-door TLS  or Full-stack TLS modes.

In order to configure pod trust bundles in “No TLS” mode, include these resources in the transformers block of your base kustomization.yaml file. These lines must come before the line that lists the required transformers, "- sas-bases/overlays/required/transformers.yaml".

```yaml
transformers:
- sas-bases/overlays/network/ingress/security/transformers/truststore-transformers-without-backend-tls.yaml # transformers to build trust stores when no backend tls is desired
- sas-bases/overlays/required/transformers.yaml # This line is provided as a location reference, it should appear only once and not be duplicated.
```

### Istio Ingress

SAS Viya does not support Istio Ingress with mTLS enabled.  For secure network communications, you must use NGINX Ingress.

## Examples kustomization.yaml Files

```yaml
#Front-door TLS with customer provided certificates
namespace: frontdoortls
resources:
- sas-bases/examples/security/sas-viya-issuer.yaml
- sas-bases/base
- sas-bases/overlays/network/ingress
- sas-bases/overlays/network/ingress/security

transformers:
- sas-bases/overlays/network/ingress/security/transformers/ingress-tls-transformers.yaml
- sas-bases/overlays/network/ingress/security/transformers/cas-connect-tls-transformers.yaml
- sas-bases/overlays/required/transformers.yaml

generators:
- site-config/security/customer-provided-ingress-certificate.yaml
- site-config/security/customer-provided-ca-certificates.yaml
```

```yaml
#Full-stack TLS with customer provided certificates
namespace: fullstacktls
resources:
- sas-bases/examples/security/sas-viya-issuer.yaml
- sas-bases/base
- sas-bases/overlays/network/ingress
- sas-bases/overlays/network/ingress/security


transformers:
- sas-bases/overlays/network/ingress/security/transformers/product-tls-transformers.yaml
- sas-bases/overlays/network/ingress/security/transformers/ingress-tls-transformers.yaml
- sas-bases/overlays/network/ingress/security/transformers/backend-tls-transformers.yaml
- sas-bases/overlays/required/transformers.yaml

generators:
- site-config/security/customer-provided-ingress-certificate.yaml
- site-config/security/customer-provided-ca-certificates.yaml
```

## Additional Resources
https://cert-manager.io/