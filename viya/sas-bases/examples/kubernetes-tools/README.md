---
category: kubernetesTools
tocprty: 1
---

# Using Kubernetes Tools from the sas-orchestration Image

## Overview

The sas-orchestration image includes the recommended versions of both
`kustomize` and `kubectl`. These tools may be used with docker's `--entrypoint`
option.

Note: All examples below are auto-generated based on your order.

## Prerequisites

To run the sas-orchestration image, Docker must be installed.

Log in to the `cr.sas.com` Docker Registry, and retrieve the `sas-orchestration` image:

```
cat sas-bases/examples/kubernetes-tools/password.txt | docker login cr.sas.com --username '09T5CW' --password-stdin
docker pull cr.sas.com/viya-4-x64_oci_linux_2-docker/sas-orchestration:1.10.2-20200914.1600115073685
```

After pulling the sas-orchestration image, there is no need to stay logged in. If desired, log out:

```
docker logout cr.sas.com
```

## Examples

### kustomize

Use the `-v` option to mount the $deploy directory into the container,
with `-v <directory name>:/deploy`, and use `-w` to set the mounted /deploy
as the working directory. The following example assumes the $deploy
directory, with a kustomization.yaml and supporting files, is at /deploy.
Note that the `kustomize` call here is a simple example. Refer to the
deployment documentation for full usage details.

```
docker run --rm \
  -v /deploy:/deploy \
  -w /deploy \
  --entrypoint kustomize \
  cr.sas.com/viya-4-x64_oci_linux_2-docker/sas-orchestration:1.10.2-20200914.1600115073685 \
  build . > site.yaml
```

### kubectl

The following example assumes a site.yaml exists in /deploy,
and a kubeconfig file exists in /home/user/kubernetes. Use `-v`
to mount the directories, and `-w` to use /deploy as the working
directory. Note that the `kubectl` call here is a simple example.
Refer to the deployment documentation for full usage details.

```
docker run --rm \
  -v /deploy:/deploy \
  -v /home/user/kubernetes:/kubernetes \
  -w /deploy \
  --entrypoint kubectl \
  cr.sas.com/viya-4-x64_oci_linux_2-docker/sas-orchestration:1.10.2-20200914.1600115073685 \
  --kubeconfig=/kubernetes/kubeconfig apply -f site.yaml
```

## Additional Resources

* https://docs.docker.com/get-docker/
* https://kustomize.io/
* https://kubectl.docs.kubernetes.io/