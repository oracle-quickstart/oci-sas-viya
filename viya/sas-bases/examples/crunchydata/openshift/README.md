#CrunchyData PostgreSQL Configuration on Openshift cluster.
This directory contains files to grant Security Context Constraints for fsgroup 26 on a openshift cluster.
Kubernetes cluster admin should add this SecurityContextConstraints to their openshift cluster prior to 
deploying SAS Viya 4. User can choose the below commands to add this scc
kubectl apply -f pgo-scc.yaml or oc create -f pgo-scc.yam