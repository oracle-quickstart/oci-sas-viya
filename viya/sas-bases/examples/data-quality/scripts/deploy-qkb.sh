#!/bin/sh

usage()
{
    cat <<EOF
Usage: $0 IMAGE

Generates Kubernetes YAML that will deploy the given QKB image into SAS Viya.

Mandatory arguments:
    IMAGE - The docker image location for the containerized QKB

EOF
    exit 1
}

generate_job()
{
    cat <<EOF

---
#
# Deployment job for QKB image "$QKB_IMAGE"
# Append this code block to $deploy/site-config/data-quality/custom-qkbs.yaml
#
apiVersion: batch/v1
kind: Job
metadata:
  labels:
    sas.com/deployment: sas-viya
  name: $JOB_NAME
spec:
  template:
    metadata:
      labels:
        app: $JOB_NAME
        app.kubernetes.io/name: $JOB_NAME
      annotations:
        sidecar.istio.io/inject: "false"
    spec:
      containers:
      - name: installer
        command:
          - sh
          - -c
          - /rdutil/sas-rdcopy.sh
        image: $QKB_IMAGE
        imagePullPolicy: IfNotPresent
        volumeMounts:
        - mountPath: /rdutil
          name: sas-rdutil-dir
        - mountPath: /tgtdata
          name: sas-quality-knowledge-base-volume
      restartPolicy: Never
      imagePullSecrets: []
      volumes:
      - configMap:
          defaultMode: 493
          name: sas-reference-data-scripts
        name: sas-rdutil-dir
      - name: sas-quality-knowledge-base-volume
        persistentVolumeClaim:
          claimName: sas-quality-knowledge-base
EOF
}

# Parse the mandatory args.
[ $# -ne 1 ] && usage

QKB_IMAGE="$1"

SUFFIX=`head /dev/urandom | tr -dc a-z0-9 | head -c 8`
JOB_NAME=sas-quality-knowledge-base-install-job-${SUFFIX}

generate_job