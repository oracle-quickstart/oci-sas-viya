# viya-on-oci

## setup

Gonna assume a DNS entry for your cluster of `kate.changeme.com` as well as a wildcard DNS of `*.kate.changeme.com` that points at the IP address of your ingress controller

### kuard sample

See `./setup/kuard`

### voto sample

See `./setup/voto`.  You dont have to consume the linkerd part, but you will have to fix the hostname in the ingress

### gelldap - a cheezy standalone LDAP provider

See `./setup/gelldap`
