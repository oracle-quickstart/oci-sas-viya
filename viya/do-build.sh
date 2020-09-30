#!/bin/bash

set -x

#
# ripped off from gokart/bahaye/do-it.sh
# added "rm detritus from last go around the swings with orchestration" so yesterdays resources that got deleted no longer bleed thru
# also fooled with ./generated so that we keep gifts from orch-tool in their own folder
# orch 1.21 starts putting it in ./bundles with --generate-for-all
#

this=$(basename "$0")

if [[ -z "$NAMESPACE" ]]; then
	echo "Oops $this expects/requires a NAMESPACE Environment Variable you muffin"
	exit 1
fi

if [[ -z "$CLUSTER" ]]; then
	echo "Oops $this expects/requires a CLUSTER Environment Variable you muffin"
	exit 1
fi

if [[ ! -d ./downloads ]]; then
        echo "Oops $this wants to see a ./downloads folder"
        exit 1
fi

. ./downloads/downloads.env

if [[ -z "$ORDER" ]]; then
	echo "Oops $this expects/requires an ORDER Environment Variable you muffin"
	exit 1
fi



# re-fetch the order; this will update its data maybe
gotzip=0
zipfile=downloads/SAS_Viya_deployment_data_$ORDER.tgz

apilev=test
#apilev=stage
apikey=`cat ~/.ssh/api$apilev.apikey`
apihost=apigateway-$apilev.sas.com
cadname=${CADENCE:fast}
cadver=2020
randofile=/tmp/download.this.$$
safehost=cldlgn04.unx.sas.com
#apiurl=https://$apihost/reofs_internal/orders/$ORDER/subOrders/70180938/cadenceNames/$cadname/cadenceVersions/$cadver/deploymentAssets
apiurl=https://$apihost/reofs_internal/orders/$ORDER/cadenceNames/$cadname/deploymentAssets

ssh $safehost curl -f -o $randofile \
  --header "X-API-KEY:$apikey" \
  --header "currentuser-mail:paul.kent@sas.com" \
  --header "Client-Application-User:kent" \
  $apiurl

curlrc=$?
echo $curlrc

if [ $curlrc -eq 0 ]
then
        gotzip=1

        scp $safehost:$randofile $zipfile
        ssh $safehost /bin/rm -f $randofile

        assets=./sas-bases
        rm -rf $assets
        tar xfz $zipfile
fi

if [ $gotzip -eq 0 ]
then
	echo "Oops ORDER=$ORDER doesnt result in a zip file."
	exit 1
fi


# read-only causes chaos with git?
chmod -R u+w $assets

# pin to this version until they get better
kz=kustomize.370
which $kz >/dev/null 2>&1
if [[ $? -ne 0 ]]
then
    kz=kustomize
fi


# go build the finalized manifests ready to apply
$kz build . --load_restrictor="none" > $NAMESPACE.yaml

# linkerd inject maybe?
if [[ -f .linkerd.please ]]
then
   mv $NAMESPACE.yaml $NAMESPACE.pre.yaml
   linkerd inject $NAMESPACE.pre.yaml > $NAMESPACE.yaml
fi


#
# ky might be useful, it breaks apart that huge yaml into folders
# brew install hornpolish/brew/ky
# or visit https://github.com/hornpolish/ky for other flavors
#
which ky >/dev/null 2>&1
if [[ $? = 0 ]]
then
    rm -rf split
    ky split -t $NAMESPACE.yaml >/dev/null
fi



# suggest how to apply the generated manifest
echo kubectl apply -n $NAMESPACE -f $NAMESPACE.yaml


