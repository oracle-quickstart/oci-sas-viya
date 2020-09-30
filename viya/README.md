# viya namespace notes

This cheat sheet assumes you have set/exported these three ENV variables:
* KUBECONFIG pointing at the required file, or have set you context in k8s-hipster-fashion
* CLUSTER is the name of the cluster
* NAMESPACE is viya

You may not need the storage patches if your default storage class can RWX


```lang=bash

export KUBECONFIG=my.cluster.conf
export CLUSTER=oci
export NAMESPACE=viya

./do-build.sh
kubectl apply -n $NAMESPACE -f $NAMESPACE.yaml

```
