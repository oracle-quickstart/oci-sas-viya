# Configure External Access to CAS

## Overview of CAS Connectivity

By default, a single CAS server is configured during the deployment process and
is accessible to SAS services and web applications that are deployed in the
Kubernetes cluster. For example, SAS Visual Analytics, SAS Studio, and other SAS
software can work with CAS and does not require any additional configuration.

In addition, an HTTP Ingress is enabled that provides access to CAS from outside
the cluster to clients that use REST. This Ingress can be used with clients such
as Python SWAT.

The Ingress Controller that is configured for your cluster enables connectivity
to CAS at an HTTP path like the following:

```text
https://www.example.com/cas-shared-default-http
```

> The default instance of the CAS server is referenced in this example and the
> rest of this document. If you add more than one server, then the Ingress or
> Service name uses the server instance name instead of the word default.

## Optional Connectivity

There are two uses of CAS that require additional configuration:

- Connecting to CAS from outside the Kubernetes cluster with binary
  communication. For example, if you want to connect to CAS from SAS Viya 3.5 or
  use a binary connection with open programming clients such as Python, R, and
  Java, you can enable a binary connection.

- Connecting to CAS from SAS Data Connect Accelerators. For information about
  enabling connectivity for SAS/ACCESS and Data Connectors, see
  `$deploy/sas-bases/examples/data-access/README.md`.

## About Binary Connectivity

Most clients can use a binary connection to the CAS server. Typically,
performance is better than HTTP because the data stream is more compact than
REST.

> If you want to connect from SAS Viya 3.5, then you must enable binary
> communication. You can use the load balancer as described here or you can
> configure a custom Ingress to proxy TCP port 5570.

## Optional Binary and HTTP Services

You can enable two Services that provide external access to CAS for programmers.
One service provides binary communication and the other service provides HTTP
communication for REST. The HTTP service is an alternative to using the HTTP
Ingress that is enabled by default.

The binary communication provides better performance but the client software
requires C language libraries to use the binary connection. Refer to the
documentation for the client, such as Python SWAT, for information about the
libraries.

If you enable either of these services, they are enabled as NodePorts by
default. To use the services as LoadBalancers, you must specify LoadBalancer as
the type. You can also set ranges of IP addresses for the load balancers to
accept traffic on.

> The CAS operator supports setting the binary and HTTP services to either
> NodePort or LoadBalancer. Setting a combination of service types is not
> supported by the operator. In addition, the DC and EPCS services that are part
> of SAS/ACCESS and Data Connectors are also affected.

## Configuration

Copy the
`$deploy/sas-bases/examples/cas/configure/cas-enable-external-services.yaml` to
your `$deploy/site-config` directory and edit it.

Set the publishBinaryService key to true to enable binary communication for
clients from outside the Kubernetes cluster.

```yaml
- op: replace
  path: /spec/publishBinaryService
  value: true
```

If you want to enable the HTTP service, set the publishHTTPService key to true.
This enables a service for REST access from outside the Kubernetes cluster. Be
aware that REST access is enabled by default through a Kubernetes Ingress. If
you have access through the Ingress, then enabling this HTTP service is
redundant.

```yaml
- op: replace
  path: /spec/publishHTTPService
  value: true
```

Finally, the services are configured as NodePort by default. If you want to
configure them as LoadBalancer services, uncomment the serviceTemplate. Setting
source ranges is optional. Delete the lines if you do not want them.

<!-- prettier-ignore-start -->
```yaml
- op: add
  path: /spec/serviceTemplate
  value:
    spec:
      type: LoadBalancer
      loadBalancerSourceRanges:
      - 192.168.0.0/16
      - 10.0.0.0/8
```
<!-- prettier-ignore-end -->

> SAS supports setting the type and loadBalancerSourceRanges keys in the service
> specification. Adding any other key such as port or selector can result in
> poor performance or prevent connectivity.

After you build and apply your manifest, you can use
`kubectl get svc sas-cas-server-default-http` and
`kubectl get svc sas-cas-server-default-bin` to identify the network port or
external IP address the maps to the service. These two services do not require
that you restart CAS. For other services related to CAS, refer to the
documentation to determine if a restart is required.

For example, if the binary connection is enabled as a NodePort, programmers can
connect to CAS though a host name for one of the nodes in the Kubernetes cluster
on port 31066.

```text
NAME                         TYPE       CLUSTER-IP   EXTERNAL-IP   PORT(S)
sas-cas-server-default-bin   NodePort   10.0.5.236   <none>        5570:31066/TCP
```

## SAS Data Connect Accelerators

The SAS Data Connect Accelerators enable parallel data transfer between a
distributed CAS server (MPP) and some data sources such as Teradata and Hadoop.
For information about enabling connectivity for SAS/ACCESS and Data Connectors,
see `$deploy/sas-bases/examples/data-access/README.md`.

## Additional Resources

For more information about CAS configuration and using example files, see the
[SAS Viya: Deployment Guide](http://documentation.sas.com/?softwareId=mysas&softwareVersion=prod&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm).

For more information about the services, see
[Kubernetes Services for CAS](http://documentation.sas.com/?softwareId=mysas&softwareVersion=prod&docsetId=k8sag&docsetTarget=p1tzcepmv5amzfn1xqztxj2vp1dx.htm).
