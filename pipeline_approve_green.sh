#!/usr/bin/env bash

#deployment=$1
deployment=busybox

blue_version=$(grep DOCKER_APP_IMAGE docker.blue-green.properties | grep -o  ':[.0-9\-]*' | sed 's/://g')

[[ $(kubectl get deploy | grep -c $deployment) -eq 1 ]] && echo "only one deployment of $1 found, blue approval/revert  requires 2 deployments !" && exit 1

[[ $(kubectl get deploy $deployment-$blue_version --no-headers | wc -l ) -ne 1 ]] && echo "blue/old deployment of $1 not found!" && exit 1

echo "deleting blue deployment: $deployment-$blue_version"

[[ $(kubectl delete deploy $deployment-$blue_version) ]] && echo "successfully deleted"


