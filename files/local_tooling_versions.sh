#!/usr/bin/env bash

# We need to return an error if things don't work
#set -e

python3 --version
pip --version
ansible --version
# version any
#unzip -v
#tar --version
#docker --version
#git --version
kustomize version
kubectl version
helm version

echo -e "\n\n\n"

pip3 list | grep "ansible" 2>/dev/null
pip3 list | grep "openshift" 2>/dev/null
pip3 list | grep "kubernetes" 2>/dev/null
pip3 list | grep "dnspython" 2>/dev/null

ansible-galaxy collection list | grep kubernetes
