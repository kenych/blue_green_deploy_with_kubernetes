#!/usr/bin/env bash


while true; do curl --retry 5 --retry-delay 3 --connect-timeout 3 10.109.14.207:8080 ; [[ $? -gt 0 ]] && exit 1;  echo `date`; sleep 1; done