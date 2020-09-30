# viya-on-oci

## setup

Gonna assume a DNS entry for your cluster of `kate.changeme.com` and a wildcard DNS of `*.kate.changeme.com` that points at the IP address of your ingress controller

### kuard sample

See `./setup/apps/kuard`

### voto sample

See `./setup/apps/voto`.  You dont have to consume the linkerd part, but you will have to fix the hostname in the ingress

### gelldap - a cheezy standalone LDAP provider

We will setup a portable OpenLDAP instance deployed to a Pod in our cluster, against which we will configure PAM and the Identities service.

```lang=bash

cd ./setup/lifeboat

kubectl create ns lifeboat

kubectl apply -n lifeboat -f openldap-configmap.yaml
kubectl apply -n lifeboat -f openldap-deployment.yaml
kubectl apply -n lifeboat -f openldap-service.yaml

```

If you are curious, you can also apply the php-ldap-admin objects inside `./setup/lifeboat`, after you correct the hostname in the ingress

