#!/usr/bin/env bash

kubectl delete deploy $(kubectl get deploy | grep busybox | awk {'print $1'})
kubectl delete service busybox

sed -i s~':[0-9]*'~:1~g docker.blue-green.properties
sed -i s~':[0-9]*'~:1~g docker.app.properties