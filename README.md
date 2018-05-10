# Possible k8s deployment strategies 
        
## Delete/create(recreate): delete all, then create from scratch

**Pros:**
Ability to deploy everything together, once it is proved to be working in some env

**Cons:**
Obviously there is a downtime involved, and it may take a while when all apps redeployed and up and running


## Rolling update: release new version by adding more replicas until new replicas equal desired replicas

**Pros:**
no downtime, version is updated replica by replica automatically, easier to automate deployment

**Cons:**
non backward APIs is an issue
no way to control version in use(current version) as it gradually rolled out and replaced by newer replicas


##blue/green deploy a new version which runs in parallel with old version, do health-check, if ok, switch traffic


**Pros:**
no downtime, instant switch over new/old version, API compatibility tolerant

**Cons:**
requires more resources, more testing, time and logic in place to control the switch

## Canary: deploy new version in a smaller chunks for smaller amount of users, if ok, the do full rollout 

**Pros:**
no downtime, only part of users affected if something goes wrong

**Cons:**
not easy to implement, not available out of box (with pure kubectl) and requires sophisticated tools 

 
# Blue/green implementation with pure kubectl 

## K8s resources need additional label for version and deployment name needs suffix so we can have 2 deployments of same app running at the same time

* Update selector with application (deployment) name and version:
service:
```
apiVersion: v1
kind: Service
metadata:
  labels:
    run: busybox1
  name: busybox1
  namespace: default  
spec:
  clusterIP: 10.109.14.207
  ports:
  - port: 8080
    protocol: TCP
    targetPort: 8080
  selector:
    deployment: busybox
    version: "$VERSION"
  sessionAffinity: None
  type: ClusterIP
status:
  loadBalancer: {}
```
* Update deployment with deployment name, and add application (deployment) label and version label:

```
piVersion: extensions/v1beta1
kind: Deployment
metadata:
  labels:
    run: busybox
  name: busybox-$VERSION
  namespace: default
  
spec:
  replicas: 1
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
    type: RollingUpdate
  template:
    metadata:
      creationTimestamp: null
      labels:
        deployment: busybox
        version: "$VERSION"
    spec:
      containers:
      - args:
        - sh
        - -c
        - while true; do { echo -e 'HTTP/1.1 200 OK\r\n';      echo 'smallest http
          server$VERSION'; } | nc -l -p  8080; done
        image: busybox
        imagePullPolicy: Always
        name: busybox2
        ports:
        - containerPort: 8080
          protocol: TCP
        resources: {}
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
      dnsPolicy: ClusterFirst
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext: {}
      terminationGracePeriodSeconds: 30
```

## Pipeline stages

* Deploy new
* Do health check
* Switch traffic from old to new
* Run tests
* if tests are OK, remove old(blue)
* if tests are NO OK, SWITCH traffic back to old(blue) and remove green(new) and redeployed once fixed a newer version

## Demo

### with pipeline:
* pipeline_clean.sh - prepare env with version 1
* pipeline_ci_run.sh - imitate upstream updated docker image, enter new version
* pipeline_update.sh [arg - default 'OK', if not test will fail] - deploys new version from upstream
* client.sh - run from inside cluster (minikube) to send retriable get requests to app
* test.sh - run from inside cluster (minikube) to test app (expects 'ok' to be returned as a response)
* pipeline_revert_green.sh - run if tests failed to revert to previous version
* pipeline_approve_green.sh - run if deployment was successful, sort of commit in transactional db, gets read of old/new second deployment

### with asciinema
* play this first https://asciinema.org/a/Xrd7WwAVmgIoLa4ngxVShw6ro
* then in another window after 5 seconds(sorry for lag :) https://asciinema.org/a/AeXQgdMEspTattivwYYKDpZE4

## Useful read 
... and thanks for strategy diagrams to: http://container-solutions.com/kubernetes-deployment-strategies/

# Is helm going to helm with helm blue green? - no..
https://github.com/kubernetes/helm/issues/3518
