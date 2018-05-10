#!/usr/bin/env bash

#deployment=$1
deployment=busybox

STATUS=$1

[[ "$(kubectl get deploy | grep -c $deployment)" != "1" ]] && echo 'must have one deployment!' && exit 0
[[ "$(kubectl get svc | grep -c $deployment)" != "1" ]] && echo 'must have one service!' && exit 0
[[ "$(kubectl get svc $deployment -o json | jq -r '.spec.selector.version+"-"+.spec.selector.deployment')" != "$(kubectl get deploy $(kubectl get deploy |  grep $deployment | awk {'print $1'}) -o json | jq -r '.spec.template.metadata.labels.version+"-"+.spec.template.metadata.labels.deployment')" ]] && echo "service / deployment mismatch!" && exit 1

# let's save  it's version as blue, pls note, our service uses deployment name and version selector
BLUE_VERSION=`kubectl get svc $deployment -o json | jq -r '.spec.selector.version'`
echo "current version/blue: $BLUE_VERSION"

export STATUS=${STATUS:=OK}

echo "deployment status will be: $STATUS"

sleep 2

GREEN_VERSION=$(grep DOCKER_APP_IMAGE docker.app.properties | grep -o  ':[.0-9\-]*' | sed 's/://g')

echo "version from upstream CI pipeline/docker version: $GREEN_VERSION"

[[ "$GREEN_VERSION" ==  "$BLUE_VERSION" ]] && echo "new version is same as old, nothing to update!"  && exit 1

export GREEN_VERSION=$GREEN_VERSION

sleep 2
 
#next interpolate our version variable in the k8s resources
envsubst< busybox_svc_DYNAMIC.tpl.yaml > busybox_svc_DYNAMIC.yaml
envsubst< busybox_dep_dynamic.tpl.yaml > busybox_dep_dynamic.yaml

echo "update deployments..."
kubectl apply -f busybox_dep_dynamic.yaml && kubectl get -f busybox_dep_dynamic.yaml

#todo do some health checks here
#deliberately removed sleep to test client for tolerancy
#sleep 5

# even with patch client attempt can fail(needs to be retried)
# kubectl patch svc busybox1 -p '{"spec": {"selector": {"deployment": "busybox", "version": "'$(echo $VERSION)'"}}}'
kubectl apply -f busybox_svc_DYNAMIC.yaml

[[ "$(kubectl get svc $deployment -o json | jq -r '.spec.selector.deployment+"-"+.spec.selector.version')" != "$deployment-$GREEN_VERSION" ]] && echo "service not set to right version!" && exit 1
echo "new deployment successfully installed"
sed -i s~':[0-9]*'~:$BLUE_VERSION~g docker.blue-green.properties

sleep 2

# at this stage we have two deployments, but service is pointing to version:
echo "list of $deployment deployments:"
kubectl get deploy  | grep $deployment

 

