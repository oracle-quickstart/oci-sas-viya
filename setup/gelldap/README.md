# install gelldap

This is a stand-in for a "real" LDAP / AD


```lang=bash

k apply -f gelldap-server.yaml

# You will need to fix the host: in the Ingress
k apply -f gelldap-admin.yaml

```
