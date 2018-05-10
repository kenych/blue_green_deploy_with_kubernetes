#!/usr/bin/env bash

. pipeline_clean.sh

kubectl apply -f busybox_dep_static.yaml -f  busybox_service_static.yaml
sed -i s~':[0-9]*'~:1~g docker.blue-green.properties
sed -i s~':[0-9]*'~:1~g docker.app.properties