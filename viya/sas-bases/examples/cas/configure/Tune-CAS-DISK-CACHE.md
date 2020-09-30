# Tune CAS_DISK_CACHE

## About CAS_DISK_CACHE

The server uses the directory or directories associated with the environment
variable CASENV_CAS_DISK_CACHE as a scratch area. It has two primary purposes:

1. As data is loaded into memory, it is organized in blocks. Each time a block
   reaches the default block size of 16Mb, the block is copied to the cache. The
   copied block can be re-read back into memory quickly if memory use becomes
   high and the original data must be freed from memory.

2. For a distributed server, copies of the blocks are transferred to another
   worker node for fault tolerance.

A secondary use of the cache is for files that are uploaded to the server. By
default, a copy of the file is temporarily stored on the controller in the
cache. You can specify a different location, see
[Storage Location for Uploaded Files](#storage-location-for-uploaded-files).

## About the Default Configuration

By default, the server is configured to use a directory that is named
`/cas/cache` on each controller and worker node. This directory is provisioned
as a Kubernetes emptyDir and uses disk space from the root volume of the
Kubernetes node.

The default configuration is acceptable for testing and evaluation, but not for
production workloads. If disk space in the root volume of the node becomes low,
then Kubernetes begins evicting pods. The pod is unlikely to be rescheduled.

When the server stores a block in the cache, the server uses a technique that
involves opening a file, deleting the file, and then holding the handle to the
deleted file. The negative consequence to this technique is that Kubernetes
cannot monitor the disk use in the cache. Specifically, setting a sizeLimit on
the emptyDir has no effect for limiting the disk use.

## Choose the Best Storage

The server uses memory mapped I/O for the blocks in the cache. The best
performance is provided by using disks that are local to the node for each
controller and worker pod. If possible, use disks that provide high data
transfer rates such as NVMe or SSD.

If you follow the best practices for workload placement, then no other pods are
scheduled for a node that is used by CAS. If the root volume is sufficiently
large, then the only disadvantage to using the default emptyDir is that
Kubernetes can evict the pod if disk space becomes low.

A better strategy is to use a disk that is attached to the node. If the server
fills the disk with blocks, the server logs an error rather than Kubernetes
evicting the pod. An end user receives the following message when the server
runs out of disk space used for the cache on any node.

```text
Cloud Analytic Services failed writing to system disk space. Please contact your
administrator.
```

> The disk that is used does not need to persist beyond the duration of the pod
> and does not need to be backed up. Ephemeral storage is ideal.

## Tips for Azure AKS

Azure VMs that are suitable for production workloads include a temporary disk
for ephemeral storage. Typically, the disk is available at `/dev/sdb1` and it is
mounted on the `/mnt` directory for the VM.

One way to use this disk for the cache is to mount it as a hostPath from the VM.
The following sample is similar to the
`$deploy/sas-bases/examples/cas/configure/cas-add-host-mount.yaml` example.

```yaml
---
apiVersion: builtin
kind: PatchTransformer
metadata:
  name: cas-volumes
patch: |-
  - op: replace
    path: /spec/controllerTemplate/spec/volumes
    value:
... If you specify replace as the operation, then include
    the volumes that you already have in use. ...
      - name: cas-default-cache-volume
        hostPath:
          path: /mnt
          type: Directory
target:
  group: viya.sas.com
  kind: CASDeployment
  name: .*
  version: v1alpha1
```

Azure offers VMs with NVMe storage. If you use these VMs, then make sure the
volume is formatted with an xfs or ext4 file system and is mounted by the VM.
Replace the mount point, `/mnt`, in the preceding example with the correct path.

## Support for Multiple Disks

If you use nodes with more than one high-performance disk, you can use more than
one disk for the cache. The server uses a round-robin algorithm for storing
blocks on multiple disks.

You can create a PatchTransformer similar to the preceding sample.

```yaml
---
apiVersion: builtin
kind: PatchTransformer
metadata:
  name: cas-volumes
patch: |-
  - op: replace
    path: /spec/controllerTemplate/spec/containers/0/volumeMounts
    value:
... Include existing volume mounts.
    Remove the cas-default-cache-volume volumeMount. ...
      - mountPath: /cas/cache-nvme0
        name: cas-cache-nvme0
      - mountPath: /cas/cache-nvme1
        name: cas-cache-nvme1
  - op: replace
    path: /spec/controllerTemplate/spec/volumes
    value:
... Include existing volumes.
    Remove the cas-default-cache-volume entry. ...
      - name: cas-cache-nvme0
        hostPath:
          path: /mnt-nvme0
          type: Directory
      - name: cas-cache-nvme1
        hostPath:
          path: /mnt-nvme1
          type: Directory
```

The preceding sample suggests that two NVMe disks are mounted on the node at
`/mnt-nvme0` and `/mnt-nvme1`. Steps to perform that action are not shown in
this documentation.

To configure the server to use the two mount points that are inside the
container, `/cas/cache-nvme0` and `/cas/cache-nvme1`, set the
CASENV_CAS_DISK_CACHE environment variable. One way to set the environment
variable is to create a patch file similar to the
`$deploy/sas-bases/examples/cas/configure/cas-add-environment-variables.yaml`
example and reference it in the transformers section of your kustomization.yaml
file.

```yaml
apiVersion: builtin
kind: PatchTransformer
metadata:
  name: cas-disk-cache
patch: |-
  - op: add
    path: /spec/controllerTemplate/spec/containers/0/env/-
    value:
      name: CASENV_CAS_DISK_CACHE
      value: "/cas/cache-nvme0:/cas/cache-nvme1"
```

Assuming that the preceding patch is written to
`$deploy/site-config/patches/cas-disk-cache.yaml`, then the update to the
kustomization.yaml file is similar to the following:

```yaml
patches:
  - target:
      group: viya.sas.com
      version: v1alpha1
      kind: CASDeployment
      name: default
    path: site-config/patches/cas-disk-cache.yaml
```

## Configure Block Size

By default, the server uses a 16 Mb block size. If the site accesses very large
tables exclusively, you can configure a larger block size to reduce the chance
of running out of file handles. Set the CASCFG_MAXTABLEMEM environment variable
to the preferred value.

If a variety of table sizes is used, then individual users can set the
MAXTABLEMEM session option on a case-by-case basis.

## Storage Location for Uploaded Files

An upload is a data transfer of an entire file to the server, such as a SAS data
set in SAS7BDAT format or a CSV file. The client, such as SAS, Python, or a web
browser, performs no processing on the file. The server performs any processing
that is needed, such as parsing records from a CSV file.

By default, when an entire file is uploaded to the server, the controller stores
a copy of the file in the cache. For a distributed server, you might not need as
much cache storage on the controller as you need on the workers because the
controller does not process rows of data.

If it is useful at your site, you can specify a different directory for uploaded
file storage. You can specify the path in the CASENV_CAS_CONTROLLER_TEMP
environment variable.
