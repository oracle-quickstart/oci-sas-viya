#!/bin/bash

#
# create-cas-server.sh
# 2020
#
# This script will take user parameters as input, and
# generate new CAS server definitions (CR) for Viya 4.

#set -x

function echo_line()
{
    line_out="$(date) - $1"
    printf "%s\n" "$line_out"
}

version="1.3"

case "$1" in
        --version | -v)
                echo "${version}"
                exit
                ;;
        --help | -h)
                echo "Flags:"
                echo "  -h  --help     help"
                echo "  -i, --instance  CAS Server instance name"
                echo "  -o, --output   Output location.  If undefined, default to working directory."
                echo "  -v, --version  CAS Server Creation Utility version"
                echo "  -w, --workers  Specify the number of CAS worker nodes. Default is 0 (SMP)."
                echo "  -b, --backup   Set this flag to 1 to include a CAS backup controller.  Disabled by default."
                exit
                ;;
esac

# declaring a couple of associative arrays
declare -A arguments=();  
declare -A variables=();

# declaring an index integer
declare -i index=1;

variables["-i"]="instance";  
variables["--instance"]="instance";  
variables["-f"]="file";  
variables["--file"]="file";
variables["-o"]="output";
variables["--output"]="output";
variables["-w"]="workers";
variables["--workers"]="workers";
variables["-b"]="backup";
variables["--backup"]="backup";


# $@ here represents all arguments passed in
for i in "$@"  
do  
  arguments[$index]=$i;
  prev_index="$(expr $index - 1)";

  # this if block does something akin to "where $i contains ="
  # "%=*" here strips out everything from the = to the end of the argument leaving only the label
  if [[ $i == *"="* ]]
    then argument_label=${i%=*} 
    else argument_label=${arguments[$prev_index]}
  fi

  exec 2> /dev/null
  # this if block only evaluates to true if the argument label exists in the variables array
  if [[ -n ${variables[$argument_label]} ]]
    then
        # dynamically creating variables names using declare
        # "#$argument_label=" here strips out the label leaving only the value
        if [[ $i == *"="* ]]
            then declare ${variables[$argument_label]}=${i#$argument_label=} 
            else declare ${variables[$argument_label]}=${arguments[$index]}
        fi
  fi
  exec 2> /dev/tty

  index=index+1;
done;

if [ ! -z "${instance}" ]; then
    echo_line "instance = $instance"
else
    echo_line "instance is not defined.  Please provide instance with either -i or --instance flag."
    exit 1
fi

if [ ! -z "${workers}" ]; then
    workers=${workers}
else
    workers=0
fi

if [ ! -z "${backup}" ]; then
    if [ $backup == "0" ] || [ $backup == "1" ]; then
        backup=${backup}
    else
        echo "invalid value for backup: $backup"
        echo "please enter 0 or 1"
        exit 1
    fi
else
    backup=0
fi

if [ ! -z "${output}" ]; then
    echo_line "output = $output"
    output=$output"/"

    if [ -d "${output}cas-${instance}" ]; then
    echo ""
    while true; do
        read -p "Content already exists in the specified output location.  Continuing will overwrite the existing content.  Do you want to continue? (y/n) " yn
        case $yn in
            [Yy]* ) make install; break;;
            [Nn]* ) exit;;
            * ) echo "Please answer yes or no.";;
        esac
    done
    rm -rf ${output}cas-${instance}
    fi

    if [ ! -d "${output}cas-${instance}" ]; then
        echo "output directory does not exist: ${output}"
        echo "creating directory: ${output}"
        mkdir -p ${output}/cas-${instance}
    fi
else

    if [ -d "cas-${instance}" ]; then
    echo ""
    while true; do
        read -p "Content already exists in the specified output location.  Continuing will overwrite the existing content.  Do you want to continue? (y/n) " yn
        case $yn in
            [Yy]* ) make install; break;;
            [Nn]* ) exit;;
            * ) echo "Please answer yes or no.";;
        esac
    done
    rm -rf  cas-${instance}
    fi
    mkdir -p cas-${instance}
fi

echo "Generating artifacts..."

count=0
total=34
pstr="[=======================================================================]"

while [ $count -lt $total ]; do
  sleep 0.025 # this is work
  count=$(( $count + 1 ))
  pd=$(( $count * 73 / $total ))
  printf "\r%3d.%1d%% %.${pd}s" $(( $count * 100 / $total )) $(( ($count * 1000 / $total) % 10 )) $pstr
done

echo ""
echo "|-cas-${instance} (root directory)"

echo "  |-cas-${instance}-cr.yaml"

  cat << EOF >> ${output}cas-${instance}/cas-${instance}-cr.yaml
apiVersion: viya.sas.com/v1alpha1
kind: CASDeployment
metadata:
  name: ${instance}
spec:
  controllerTemplate:
   apiVersion: viya.sas.com/v1alpha1
kind: CASDeployment
metadata:
  annotations:
    sas.com/sas-access-config: "true"
    sas.com/config-init-mode: "initcontainer"
  labels:
    app: sas-cas-operator
    app.kubernetes.io/instance: "${instance}"
    app.kubernetes.io/name: "cas"
    app.kubernetes.io/managed-by: sas-cas-operator
    sas.com/admin: "namespace"
    workload.sas.com/class: cas
  name: "${instance}"
spec:
  controllerTemplate:
    spec:
      tolerations:
      - key: "workload.sas.com/class"
        operator: "Equal"
        value: "cas"
        effect: "NoSchedule"
      affinity:
        nodeAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            preference:
              matchExpressions:
              - key: workload.sas.com/class
                operator: In
                values:
                - cas
          - weight: 1
            preference:
              matchExpressions:
              - key: workload.sas.com/class
                operator: NotIn
                values:
                - compute
                - stateless
                - stateful
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: kubernetes.azure.com/mode
                operator: NotIn
                values:
                - system
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app.kubernetes.io/name
                  operator: In
                  values:
                  - sas-cas-server
              topologyKey: kubernetes.io/hostname
      initContainers:
      - image: sas-config-init
        name: sas-config-init
        env: []
        envFrom:
          - configMapRef:
              name: sas-go-config
          - configMapRef:
              name: sas-shared-config
        volumeMounts:
          - mountPath: /cas/config/
            name: cas-default-config-volume
      containers:
      - name: cas  # required name for the CAS container
        readinessProbe:
          httpGet:
            path: /internal/state
            port: 8777
          initialDelaySeconds: 3
          periodSeconds: 3
        #args:  # change the command so we can manually run the entrypoint script and debug cas
          #- while true; do sleep 30; done;
        #command:
          #- /bin/bash
          #- -c
          #- --
        env:
        #- name: CASCFG_SERVICESBASEURL  # Can be supplied automatically in future.
          #valueFrom:
            #configMapKeyRef:
              #name: sas-shared-config-k5d4tc69g7
              #key: SAS_URL_SERVICE_TEMPLATE
        #- name: CASENV_CONSUL_TOKEN  # Can be supplied automatically in future.
          #valueFrom:
            #configMapKeyRef:
              #name: sas-shared-config-h95fdtg2gc
              #key: CONSUL_TOKEN
        - name: CASENV_CONSUL_NAME
          value: "cas-shared-${instance}"
        - name: CASENV_CAS_VIRTUAL_PATH
          value: "/cas-shared-${instance}-http"
        - name: SAS_LICENSE
          valueFrom:
            secretKeyRef:
              key: SAS_LICENSE
              name: sas-cas-license
        envFrom:
        - configMapRef:
            name: sas-shared-config
        - configMapRef:
            name: sas-java-config
        - configMapRef:
            name: sas-access-config
        - secretRef:
            name: sas-consul-client
        image: sas-cas-server
        resources:
          requests:
            memory: 2Gi
            cpu: 250m
        volumeMounts:
        #- name: bigdisk
          #mountPath: "/bigdisk" # Example of mount supplied by user
        - name: cas-default-permstore-volume
          mountPath: /cas/permstore
        - name: cas-default-data-volume
          mountPath: /cas/data
        - name: cas-default-cache-volume
          mountPath: /cas/cache
        - name: cas-default-config-volume
          mountPath: /cas/config
        - name: cas-license-volume
          mountPath: /cas/license
      imagePullSecrets:
      - name: sas-image-pull-secrets
      serviceAccountName: sas-cas-server
      volumes:
      - name: cas-default-permstore-volume
        persistentVolumeClaim:
          claimName: cas-${instance}-permstore
      - name: cas-default-data-volume
        persistentVolumeClaim:
          claimName: cas-${instance}-data
      - name: cas-default-cache-volume
        emptyDir: {}
      - name: cas-default-config-volume
        emptyDir: {}
      - name: cas-license-volume
        secret:
          secretName: sas-cas-license
          items:
          - key: SAS_LICENSE
            path: license.sas
  workers: ${workers}
  backupControllers: ${backup}
  workerTemplate:
    #podSpec - optional worker template
  publishHTTPIngress: false
  ingressTemplate:
    spec:
      rules:
      - host: \$(INGRESS_HOST)
    metadata:
      annotations: {}
      labels: {}
EOF

echo "  |-kustomization.yaml"

  cat << EOF >> ${output}cas-${instance}/kustomization.yaml
resources:
- ${instance}-pvc.yaml
- provider-pvc.yaml
- cas-${instance}-cr.yaml
configurations:
- kustomizeconfig.yaml
transformers:
- cas-sssd-sidecar.yaml
- cas-fsgroup-security-context.yaml
- annotations.yaml
- backup-agent-patch.yaml
EOF

echo "  |-${instance}-pvc.yaml"

  cat << EOF >> ${output}cas-${instance}/${instance}-pvc.yaml
apiVersion: viya.sas.com/v1alpha1
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: cas-${instance}-permstore
  labels:
    sas.com/backup-role: provider
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 100Mi
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: cas-${instance}-data
  labels:
    sas.com/backup-role: provider
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 8Gi
EOF

echo "  |-annotations.yaml"

  cat << EOF >> ${output}cas-${instance}/annotations.yaml
apiVersion: builtin
kind: AnnotationsTransformer
metadata:
  name: annotations-transformer
annotations:
  sas.com/component-name: sas-cas-operator
fieldSpecs:
- path: metadata/annotations
  create: true
EOF

echo "  |-backup-agent-patch.yaml"
    cat << EOF >> ${output}cas-${instance}/backup-agent-patch.yaml
apiVersion: builtin
kind: PatchTransformer
metadata:
  name: cas-backup-patch1
patch: |-
  - op: add
    path: /metadata/labels/sas.com~1backup-role
    value:
      "provider"
target:
  annotationSelector: sas.com/component-name=sas-cas-operator
  group: viya.sas.com
  kind: CASDeployment
  version: v1alpha1
---
apiVersion: builtin
kind: PatchTransformer
metadata:
  name: cas-backup-patch2
patch: |-
  - op: add
    path: /spec/controllerTemplate/spec/containers/-
    value:
      env:
      - name: SAS_TLS_SKIP_VERIFY
        value: "true"
      - name: BACKUP_MOUNT_LOCATION
        value: /sasviyabackup
      - name: BACKUP_SOURCE_MOUNTS
        value: cas-default-data-volume
      - name: cas-default-data-volume
        value: /cas/data
      - name: NAME
        valueFrom:
          fieldRef:
            fieldPath: metadata.labels['casoperator.sas.com/cas-env-consul-name']
      - name: CAS_NODE_TYPE
        valueFrom:
          fieldRef:
            fieldPath: metadata.labels['casoperator.sas.com/node-type']
      - name: CAS_CONTROLLER_ACTIVE
        valueFrom:
          fieldRef:
            fieldPath: metadata.labels['casoperator.sas.com/controller-active']
      - name: CAS_CFG_MODE
        valueFrom:
          fieldRef:
            fieldPath: metadata.labels['casoperator.sas.com/cas-cfg-mode']
      - name: CAS_SERVICE_NAME
        valueFrom:
          fieldRef:
            fieldPath: metadata.labels['casoperator.sas.com/service-name']
      envFrom:
      - configMapRef:
          name: sas-go-config
      - configMapRef:
          name: sas-shared-config
      - configMapRef:
          name: sas-java-config
      - configMapRef:
          name: sas-backup-agent-parameters
      - secretRef:
          name: sas-consul-client
      image: sas-backup-agent
      lifecycle:
        preStop:
          exec:
            command: ["bash", "-c", "kill -SIGKILL \$(ps -Af | grep 'backup-agent'  | grep -v grep | awk '{print \$2}')"]
      resources:
        requests:
          memory: 2Gi
          cpu: 100m
        limits:
          memory: 2Gi
          cpu: 100m
      imagePullPolicy: IfNotPresent
      name: sas-backup-agent
      terminationMessagePath: /dev/termination-log
      terminationMessagePolicy: File
      volumeMounts:
      - name: backup
        mountPath: /sasviyabackup
      - name: cas-default-data-volume
        mountPath: /cas/data
target:
  group: viya.sas.com
  kind: CASDeployment
  version: v1alpha1
  annotationSelector: sas.com/component-name=sas-cas-operator
---
apiVersion: builtin
kind: PatchTransformer
metadata:
  name: cas-backup-patch3
patch: |-
  - op: add
    path: /spec/controllerTemplate/spec/volumes/-
    value:
      name: backup
      persistentVolumeClaim:
        claimName: sas-cas-backup-data-${instance}
  - op: add
    path: /spec/controllerTemplate/spec/containers/0/volumeMounts/-
    value:
      name: backup
      mountPath: /sasviyabackup
  - op: add
    path: /spec/controllerTemplate/spec/containers/0/envFrom/-
    value:
      configMapRef:
        name: sas-restore-job-parameters
target:
  annotationSelector: sas.com/component-name=sas-cas-operator
  group: viya.sas.com
  kind: CASDeployment
  version: v1alpha1
EOF

echo "  |-cas-fsgroup-security-context.yaml"

  cat << EOF >> ${output}cas-${instance}/cas-fsgroup-security-context.yaml
apiVersion: builtin
kind: PatchTransformer
metadata:
  name: cas-apply-security-context
patch: |-
  - op: add
    path: /spec/controllerTemplate/spec/securityContext
    value:
        runAsUser: 1001
        runAsGroup: 1001
        fsGroup: 1001

target:
  group: viya.sas.com
  kind: CASDeployment
  name: .*
  version: v1alpha1
EOF

echo "  |-cas-sssd-sidecar.yaml"

  cat << EOF >> ${output}cas-${instance}/cas-sssd-sidecar.yaml
apiVersion: builtin
kind: PatchTransformer
metadata:
  name: cas-sssd-sidecar
patch: |-
  - op: add
    path: /spec/controllerTemplate/spec/containers/-
    value:
      env:
      - name: SAS_K8S_DEPLOYMENT_NAME
        value: "sas-sssd-server"
      image: sas-sssd-server
      name: sssd
      lifecycle:
        preStop:
          exec:
            command: ["bash", "-c", "kill -SIGKILL \$(ps -Af | grep '/opt/sas/viya/home/bin/consul-template'  | grep -v grep | awk '{print \$2}')", "kill -SIGKILL \$(ps -Af | grep '/sbin/sssd'  | grep -v grep | awk '{print \$2}')"]
      securityContext:
        runAsGroup: 0
        runAsUser: 0
      resources:
        requests:
          memory: 512Mi
          cpu: 100m
        limits:
          memory: 512Mi
          cpu: 100m
      envFrom:
      - configMapRef:
          name: sas-shared-config
      - configMapRef:
          name: sas-java-config
      - secretRef:
          name: sas-consul-client
      volumeMounts:
       - mountPath: /var/lib/sss
         name: sss
    volumes:
    - emptyDir: {}
      name: sss
target:
  group: viya.sas.com
  kind: CASDeployment
  name: .*
  version: v1alpha1
---
apiVersion: builtin
kind: PatchTransformer
metadata:
  name: cas-container-sssd-mounts
patch: |-
  - op: add
    path: /spec/controllerTemplate/spec/volumes/-
    value:
      name: sss
      emptyDir: {}
  - op: add
    path: /spec/controllerTemplate/spec/containers/0/volumeMounts/-
    value:
      name: sss
      mountPath: /var/lib/sss
target:
  group: viya.sas.com
  kind: CASDeployment
  name: .*
  version: v1alpha1
EOF

echo "  |-kustomizeconfig.yaml"

  cat << EOF >> ${output}cas-${instance}/kustomizeconfig.yaml
nameReference:
- kind: ConfigMap
  version: v1
  fieldSpecs:
  - path: spec/controllerTemplate/spec/containers/envFrom/configMapRef/name
    kind: CASDeployment
  - path: spec/controllerTemplate/spec/initContainers/envFrom/configMapRef/name
    kind: CASDeployment
  - path: spec/controllerTemplate/spec/containers/env/valueFrom/configMapKeyRef/name
    kind: CASDeployment
  - path: spec/controllerTemplate/spec/initContainers/env/valueFrom/configMapKeyRef/name
    kind: CASDeployment
  - path: spec/controllerTemplate/spec/volumes/configMap/name
    kind: CASDeployment
- kind: Secret
  version: v1
  fieldSpecs:
  - path: spec/controllerTemplate/spec/containers/env/valueFrom/secretKeyRef/name
    kind: CASDeployment
  - path: spec/controllerTemplate/spec/initContainers/env/valueFrom/secretKeyRef/name
    kind: CASDeployment
- kind: Secret
  version: v1
  fieldSpecs:
  - path: spec/controllerTemplate/spec/imagePullSecrets/name
    kind: CASDeployment
varReference:
  - path: spec/ingressTemplate/spec/rules/host
    kind: CASDeployment
  - path: spec/ingressTemplate/spec/tls/hosts
    kind: CASDeployment
EOF

echo "  |-provider-pvc.yaml"

  cat << EOF >> ${output}cas-${instance}/provider-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  labels:
    sas.com/backup-role: "storage"
  name: sas-cas-backup-data-${instance}
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 4Gi
EOF

echo "  |-enable-binary-port.yaml"

  cat << EOF >> ${output}cas-${instance}/enable-binary-port.yaml.yaml
# PatchTransformer to set and publish binary ports for CAS
---
apiVersion: builtin
kind: PatchTransformer
metadata:
  name: cas-publish-binary
patch: |-
   - op: add
     path: /spec/publishBinaryService
     value: true
target:
  group: viya.sas.com
  kind: CASDeployment
  name: .*
  version: v1alpha1
EOF

echo "  |-enable-http-port.yaml"

  cat << EOF >> ${output}cas-${instance}/enable-http-port.yaml
# PatchTransformer to set and publish HTTP ports for CAS
---
apiVersion: builtin
kind: PatchTransformer
metadata:
  name: cas-publish-http
patch: |-
   - op: add
     path: /spec/publishHTTPService
     value: true
target:
  group: viya.sas.com
  kind: CASDeployment
  name: .*
  version: v1alpha1
EOF


#echo "[=======================================================================]"
echo ""
echo "create-cas-server.sh complete!"
echo ""

exit 0
