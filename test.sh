#!/usr/bin/env bash

[[ $(curl --retry 1 --retry-delay 1 -s --connect-timeout 1 10.109.14.207:8080 | grep -ci "status OK") -eq 1 ]] && echo "ok" || echo "failed"

