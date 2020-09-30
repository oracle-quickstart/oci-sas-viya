# install kuard


```lang=bash

k apply -f namespace.yaml
k apply -f deployment.yaml
k apply -f service.yaml

# will need your hostname in here
k apply -f ingress.yaml

```
