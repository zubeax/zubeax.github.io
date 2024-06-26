---
layout: post
title: "Installing Docker and a Private Registry"
date: 2023-12-11
category: topics
tags: kubernetes cicd
description: >
  Install a private docker registry and configure our cluster to accept it as an image source.
---
Now that we can expose our services outside the cluster it is time to look into setting up a build pipeline for 
our own images in earnest.

In this article we are going to install Docker and a private Image Registry. Convincing containerd to accept images
from that registry will take some persuasion, but don't worry, we will succeed.

- Table of Contents
{:toc .large-only}

### Installing Docker on k3s

I will look into options to create docker images by running the build process inside a container at a later time. For the moment i am content to use a docker installation on the master node.
After trying (and failing) to install from the OS packages i decided to use the install script from [get.docker.com](https://get.docker.com). The script requires sudo entitlements, the installation process is straightforward.

<b>N.B.</b> I looked into running docker root-less, but since it is a temporary solution i decided it was not worth the trouble. If you want to go ahead with rootless operation, follow the instructions at the end of the installation log. The required scripts are present in /usr/bin.

```sh
# curl -fsSL https://get.docker.com -o get-docker.sh

# ./get-docker.sh
# Executing docker install script, commit: e5543d473431b782227f8908005543bb4389b8de
+ sh -c apt-get update -qq >/dev/null
+ sh -c DEBIAN_FRONTEND=noninteractive apt-get install -y -qq apt-transport-https ca-certificates curl >/dev/null
+ sh -c install -m 0755 -d /etc/apt/keyrings
+ sh -c curl -fsSL "https://download.docker.com/linux/debian/gpg" | gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
+ sh -c chmod a+r /etc/apt/keyrings/docker.gpg
+ sh -c echo "deb [arch=arm64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian bullseye stable" > /etc/apt/sources.list.d/docker.list
+ sh -c apt-get update -qq >/dev/null
+ sh -c DEBIAN_FRONTEND=noninteractive apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-ce-rootless-extras docker-buildx-plugin >/dev/null
+ sh -c docker version
Client: Docker Engine - Community
 Version:           24.0.6
 API version:       1.43
 Go version:        go1.20.7
 Git commit:        ed223bc
 Built:             Mon Sep  4 12:31:36 2023
 OS/Arch:           linux/arm64
 Context:           default

Server: Docker Engine - Community
 Engine:
  Version:          24.0.6
  API version:      1.43 (minimum version 1.12)
  Go version:       go1.20.7
  Git commit:       1a79695
  Built:            Mon Sep  4 12:31:36 2023
  OS/Arch:          linux/arm64
  Experimental:     false
 containerd:
  Version:          1.6.24
  GitCommit:        61f9fd88f79f081d64d6fa3bb1a0dc71ec870523
 runc:
  Version:          1.1.9
  GitCommit:        v1.1.9-0-gccaecfc
 docker-init:
  Version:          0.19.0
  GitCommit:        de40ad0

================================================================================

To run Docker as a non-privileged user, consider setting up the
Docker daemon in rootless mode for your user:

    dockerd-rootless-setuptool.sh install

Visit https://docs.docker.com/go/rootless/ to learn about rootless mode.


To run the Docker daemon as a fully privileged service, but granting non-root
users access, refer to https://docs.docker.com/go/daemon-access/

WARNING: Access to the remote API on a privileged Docker daemon is equivalent
         to root access on the host. Refer to the 'Docker daemon attack surface'
         documentation for details: https://docs.docker.com/go/attack-surface/

================================================================================  
```

<b>docker</b> Installation Log
{:.figcaption}

### Verifying successful installation

Running the 'docker version' command should get you output similar to the one below.

```sh
# docker version

Client: Docker Engine - Community
 Version:           24.0.7
 API version:       1.43
 Go version:        go1.20.10
 Git commit:        afdd53b
 Built:             Thu Oct 26 09:08:29 2023
 OS/Arch:           linux/arm64
 Context:           default

Server: Docker Engine - Community
 Engine:
  Version:          24.0.7
  API version:      1.43 (minimum version 1.12)
  Go version:       go1.20.10
  Git commit:       311b9ff
  Built:            Thu Oct 26 09:08:29 2023
  OS/Arch:          linux/arm64
  Experimental:     false
 containerd:
  Version:          1.6.25
  GitCommit:        d8f198a4ed8892c764191ef7b3b06d8a2eeb5c7f
 runc:
  Version:          1.1.10
  GitCommit:        v1.1.10-0-g18a0cb0
 docker-init:
  Version:          0.19.0
  GitCommit:        de40ad0
```

### Installing a private Docker Registry

We are going to install the registry straight from a docker hub image, so we have to define the required Kubernetes objects on our own. The .yaml file below takes care of that. When you apply it it will create :

- the 'docker-registry' namespace
- a Longhorn Persistent Volume Claim 'docker-registry'
- a Service exposing the registry port 5000
- a Deployment configuration that identifies the image to pull (v2) and sets a number of environment variables.
- a MetalLB Load Balancer service that exposes the registry with a cluster-external IP address


```sh
#File: 'docker-registry.yaml'
cat > ./docker-registry.yaml << EOT
---
apiVersion: v1
kind: Namespace
metadata:
    name: docker-registry
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: docker-registry
  namespace: docker-registry
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: longhorn
  resources:
    requests:
      storage: 15Gi
---
apiVersion: v1
kind: Service
metadata:
  name: docker-registry-service
  namespace: docker-registry
  labels:
    run: docker-registry
spec:
  selector:
    app: docker-registry
  ports:
    - protocol: TCP
      port: 5000
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: docker-registry
  namespace: docker-registry
  labels:
    app: docker-registry
spec:
  replicas: 1
  selector:
    matchLabels:
      app: docker-registry
  template:
    metadata:
      labels:
        app: docker-registry
    spec:
      containers:
      - name: docker-registry
        image: registry:2
        ports:
        - containerPort: 5000
          protocol: TCP
        volumeMounts:
        - name: storage
          mountPath: /var/lib/registry
        env:
        - name: REGISTRY_HTTP_ADDR
          value: :5000
        - name: REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY
          value: /var/lib/registry
      volumes:
        - name: storage
          persistentVolumeClaim:
            claimName: docker-registry
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: docker-registry
  name: docker-registry-lb
  namespace: docker-registry
spec:
  type: LoadBalancer
  ports:
  - port: 5000
    protocol: TCP
    targetPort: 5000
  selector:
    app: docker-registry
EOT

kubectl apply -f docker-registry.yaml
```

####  Verifying successful installation

List the kubernetes resources in the 'docker-registry' namespace :

```sh
$ kubectl -n docker-registry get all -o wide
NAME                                   READY   STATUS    RESTARTS   AGE    IP            NODE       NOMINATED NODE   READINESS GATES
pod/docker-registry-7596d688dd-x574l   1/1     Running   0          4d6h   10.42.1.121   rbpic0n2   <none>           <none>

NAME                              TYPE           CLUSTER-IP     EXTERNAL-IP       PORT(S)          AGE   SELECTOR
service/docker-registry-service   ClusterIP      10.43.90.47    <none>            5000/TCP         28d   app=docker-registry
service/docker-registry-lb        LoadBalancer   10.43.241.23   192.168.100.153   5000:31881/TCP   28d   app=docker-registry

NAME                              READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS        IMAGES       SELECTOR
deployment.apps/docker-registry   1/1     1            1           28d   docker-registry   registry:2   app=docker-registry

NAME                                         DESIRED   CURRENT   READY   AGE   CONTAINERS        IMAGES       SELECTOR
replicaset.apps/docker-registry-7596d688dd   1         1         1       28d   docker-registry   registry:2   app=docker-registry,pod-template-hash=7596d688dd
```

Looks good. Let's verify that the persistent volume claim has been provisioned.

```sh
$ kubectl -n docker-registry get pvc -o wide
NAME              STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE   VOLUMEMODE
docker-registry   Bound    pvc-3900fd18-80ad-420d-9734-9b03e945c6cc   15Gi       RWO            longhorn       28d   Filesystem
```

Ja, looks good as well. Finally let's check the registry log.

```sh
$ kubectl logs -n docker-registry pod/docker-registry-7596d688dd-x574l

time="2023-12-11T21:55:03.258861361Z" level=info msg="Starting upload purge in 41m0s" go.version=go1.20.8 instance.id=790fd057-56ea-4fc4-a1ce-498828a91271 service=registry version=2.8.3 ...
time="2023-12-11T21:55:03.258670013Z" level=warning msg="No HTTP secret provided - generated random secret. This may cause problems with uploads if multiple registries are behind a load-...
time="2023-12-11T21:55:03.259068523Z" level=info msg="redis not configured" go.version=go1.20.8 instance.id=790fd057-56ea-4fc4-a1ce-498828a91271 service=registry version=2.8.3           ...
time="2023-12-11T21:55:03.259448312Z" level=info msg="using inmemory blob descriptor cache" go.version=go1.20.8 instance.id=790fd057-56ea-4fc4-a1ce-498828a91271 service=registry version=...
time="2023-12-11T21:55:03.260292794Z" level=info msg="restricting TLS version to tls1.2 or higher" go.version=go1.20.8 instance.id=790fd057-56ea-4fc4-a1ce-498828a91271 service=registry v...
time="2023-12-11T21:55:03.260384699Z" level=info msg="restricting TLS cipher suites to: TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_ECDSA_WITH...
time="2023-12-11T21:55:03.264072343Z" level=info msg="listening on [::]:5000, tls" go.version=go1.20.8 instance.id=790fd057-56ea-4fc4-a1ce-498828a91271 service=registry version=2.8.3    ...
time="2023-12-11T21:55:42.13543949Z" level=info msg="response completed" go.version=go1.20.8 http.request.host="registry.k3s.kippel.de:5000" http.request.id=b5764d68-624b-4249-8343-8c743...
```

Ok. The registry is up. Let's see if we can talk to it. The registry should be empty, right ?

```sh
$ curl -s -X GET http://registry.k3s.kippel.de:5000/v2/_catalog
{"repositories":[]}
```

Well, it is. We can tick that box.
<br/><br/>
<b>CAVEAT:</b> Remember the [Customizing a k3s Kubernetes Cluster]({{"/kubernetes/k3s/2023-12-08-customizing-k3s/#dns-resolution-of-loadbalancer-services" | relative_url }}) blog ? At the end i mentioned that i had added a number of cluster-external ip addresses to the <b>/etc/dnsmasq.hosts</b> configuration file of my dnsmasq service. 'registry.k3s.kippel.de' was one of them. That is the reason i can use a host name in that curl command.

### Configuring Kubernetes for the Private Registry

There are 2 configuration actions left that have to be completed before Docker and Kubernetes can access our private registry.
<br/>
Docker requires a configuration file that instructs it to accept an 'insecure registry', i.e. a registry that is exposed via http, not https.

```sh
#File: '/etc/docker/daemon.json'
# cat > /etc/docker/daemon.json << EOT
{ "insecure-registries":["registry.k3s.kippel.de:5000","192.168.100.153:5000"] }
EOT
```
<br/>
For Kubernetes we use the registry not just for storing our homegrown images but also as a mirror for Internet registries. This is what the 'mirrors' clause is for.

```sh
#File: '/etc/rancher/k3s/registries.yaml'
# cat > /etc/rancher/k3s/registries.yaml << EOT
mirrors:
  "192.168.100.153":
    endpoint:
      - "http://192.168.100.153:5000"
  docker.io:
    endpoint:
      - "http://registry.k3s.kippel.de:5000"
  "registry.k3s.kippel.de":
    endpoint:
      - "http://registry.k3s.kippel.de:5000"
EOT
```

### Copy an image from docker hub to our private registry

One way to have images available in our registry (apart from building them from scratch) is to download them from an internet registry and then push them to our private registry.
This is quite useful for scenarios where we want to customize an existing image (e.g. add a spring boot application to a base image with an installed jdk).
Here is how it works :

- pull the image from docker.io into the docker registry

```sh
# docker pull nginx
Using default tag: latest
latest: Pulling from library/nginx
2c6d21737d83: Pull complete 
0bf6824a0232: Pull complete 
f47d5fcfb558: Pull complete 
ecba2628ac35: Pull complete 
1d082d8e4ce1: Pull complete 
b2b90333fd43: Pull complete 
0ef920b5aa7f: Pull complete 
Digest: sha256:10d1f5b58f74683ad34eb29287e07dab1e90f10af243f151bb50aa5dbb4d62ee
Status: Downloaded newer image for nginx:latest
docker.io/library/nginx:latest
```
- tag the image for our private registry

```sh
# docker images
REPOSITORY                                                  TAG       IMAGE ID       CREATED        SIZE
nginx                                                       latest    5628e5ea3c17   3 weeks ago    192MB

# docker tag docker.io/nginx:latest registry.k3s.kippel.de:5000/nginx:latest

# docker images
REPOSITORY                                                  TAG       IMAGE ID       CREATED        SIZE
nginx                                                       latest    5628e5ea3c17   3 weeks ago    192MB
registry.k3s.kippel.de:5000/nginx                           latest    5628e5ea3c17   3 weeks ago    192MB
```

- push the image to our private registry and remove it from the docker registry (saves some disk space)

```sh
# docker push registry.k3s.kippel.de:5000/nginx:latest
The push refers to repository [registry.k3s.kippel.de:5000/nginx]
3033c8a8ba59: Pushed 
cb1c835f32b9: Pushed 
94677b587bab: Pushed 
0367492d0972: Pushed 
21bb29481bb4: Pushed 
66544fa913ad: Pushed 
f4e4d9391e13: Pushed 
latest: digest: sha256:736342e81e97220f954b8c33846ba80d2d95f59b30225a5c63d063c8b250b0ab size: 1778

# docker rmi nginx:latest
Untagged: nginx:latest
Untagged: nginx@sha256:10d1f5b58f74683ad34eb29287e07dab1e90f10af243f151bb50aa5dbb4d62ee
```

The 'curl' command from above should now show the nginx image.

```sh
$ curl -s -X GET http://registry.k3s.kippel.de:5000/v2/_catalog
{"repositories":["nginx"]}
```

Bless me ! So it does.


## Conclusion

Slowly but surely we are getting there. Now that we have Docker and our Private Registry available it is time to roll our own and start building images. 
I will tackle this in the next Blog.

Stay tuned !
