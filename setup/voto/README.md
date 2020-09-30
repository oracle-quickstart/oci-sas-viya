# install emojivoto

See here: https://github.com/BuoyantIO/emojivoto

## plain old voto

```lang=bash

kustomize build . > install.yaml
kubectl apply -f install.yaml

```



## now with linkerd

```lang=bash

kustomize build . | linkerd inject - > install.yaml
kubectl apply -f install.yaml

```
