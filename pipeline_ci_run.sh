#!/usr/bin/env bash

echo "enter new docker version:"
read docker_image_version

sed -i s~':[0-9]*'~:$docker_image_version~g docker.app.properties

echo "docker version has been updated:"
cat docker.app.properties
