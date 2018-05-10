#!/usr/bin/env bash

#deployment=$1
deployment=busybox

blue_version=$(grep DOCKER_APP_IMAGE docker.blue-green.properties | grep -o  ':[.0-9\-]*' | sed 's/://g')

[[ $(kubectl get deploy | grep -c $deployment) -eq 1 ]] && echo "only one deployment of $1 found, blue approval/revert requires 2 deployments !" && exit 1

[[ $(kubectl get deploy $deployment-$blue_version --no-headers | wc -l ) -ne 1 ]] && echo "blue/old deployment of $1 not found!" && exit 1

green=$(kubectl get svc $deployment -o json | jq -r '.spec.selector.version')

echo "rolling back deployment for $deployment from version $green to $blue_version"


GREEN_VERSION=$blue_version
export GREEN_VERSION=$GREEN_VERSION

#next interpolate our version variable in the k8s recources
envsubst< busybox_svc_DYNAMIC.tpl.yaml > busybox_svc_DYNAMIC.yaml

kubectl apply -f busybox_svc_DYNAMIC.yaml

echo "deleting green deployment: $deployment-$green"

[[ $(kubectl delete deploy $deployment-$green) ]] && echo "successfully deleted"





