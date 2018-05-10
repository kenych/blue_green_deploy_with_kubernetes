#!/usr/bin/env bash

echo " ===== deployment ===== "
kubectl get deploy | grep busybox
echo " ====== service ====== "
kubectl get svc | grep busybox

