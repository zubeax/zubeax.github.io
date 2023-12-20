---
layout: post
title: "Building and Deploying our own Images"
date: 2023-12-12
categories: kubernetes docker imagebuild
description: >
  Establish a process to build our own container images and deploy them to the cluster.
---
- Table of Contents
{:toc .large-only}

Slowly but surely our homegrown cluster becomes usable. We can

- instantiate services either from our private registry or any internet image registry
- provide our services with persistent storage that survives a cluster restart
- expose a service either with a cluster-external ip address or an Ingress Route proxied by Traefik

Today i am going to cover the basics of performing a docker build, pushing the built image to our private registry and finally deploying a service that uses the built image.

If you want to run this example in your own environment clone the github repository

[https://github.com/zubeax/simple-quiz.git](https://github.com/zubeax/simple-quiz)

Retracing my steps does not require you to wait until Scartaris's shadow caresses the crater of Snaefells Jökull. But you won't (for good or worse) make it to the center of the earth either.

Enjoy the trip.

## Docker Build<a name="dockerbuild"></a>

The 'build.sh' script in the repository root kicks off a regular docker build from the contents of the repo (this is what the trailing '.' is for). After the build is complete the 'docker push' command pushes the image to our private registry.

```sh
REGISTRY=registry.k3s.kippel.de:5000
IMAGE=/development/flask/simple-quiz
TAG=v0.9

docker build --progress=plain -t ${REGISTRY}${IMAGE}:${TAG} . 
docker push ${REGISTRY}${IMAGE}:${TAG} 
```

The service is a flask-based python application. It requires python and a python venv environment with the packages from 'requirements.txt' installed. Since the build sets out from a plain-vanilla debian image, we have quite a bit of customizing to do.

```dockerfile
FROM debian:latest

LABEL maintainer="axel@kippel.de"

USER root

RUN apt-get update && apt-get -y install build-essential python3 python3-pip python3-dev python3-venv

ADD ./app/ /app

RUN python3 -m venv /app/quizenv
RUN . /app/quizenv/bin/activate && pip3 install -r /app/requirements.txt

#we need a numeric user to be compliant with OCP rules
RUN chown -R 1000480000 /app
USER 1000480000

EXPOSE 8000

CMD cd /app && . /app/quizenv/bin/activate && /app/quizenv/bin/gunicorn --bind=0.0.0.0 --timeout 600 --log-level debug quiz:app
```

Here is the build log. Nothing special to remark.

```sh
#0 building with "default" instance using docker driver

#1 [internal] load .dockerignore
#1 transferring context: 2B 0.0s done
#1 DONE 0.0s

#2 [internal] load build definition from Dockerfile
#2 transferring dockerfile: 659B 0.0s done
#2 DONE 0.0s

#3 [internal] load metadata for docker.io/library/debian:latest
#3 DONE 0.5s

#4 [1/7] FROM docker.io/library/debian:latest@sha256:133a1f2aa9e55d1c93d0ae1aaa7b94fb141265d0ee3ea677175cdb96f5f990e5
#4 CACHED

#5 [internal] load build context
#5 transferring context: 2.93kB 0.1s done
#5 DONE 0.1s

#6 [2/7] RUN apt-get update && apt-get -y install build-essential python3 python3-pip python3-dev python3-venv
#6 0.905 Get:1 http://deb.debian.org/debian bookworm InRelease [151 kB]
#6 1.009 Get:2 http://deb.debian.org/debian bookworm-updates InRelease [52.1 kB]
#6 1.011 Get:3 http://deb.debian.org/debian-security bookworm-security InRelease [48.0 kB]
#6 1.293 Get:4 http://deb.debian.org/debian bookworm/main arm64 Packages [8685 kB]
#6 2.530 Get:5 http://deb.debian.org/debian bookworm-updates/main arm64 Packages [6672 B]
#6 2.532 Get:6 http://deb.debian.org/debian-security bookworm-security/main arm64 Packages [124 kB]
#6 5.054 Fetched 9067 kB in 4s (2154 kB/s)
#6 5.054 Reading package lists...
#6 6.883 Reading package lists...
#6 8.566 Building dependency tree...
#6 8.981 Reading state information...
#6 9.948 The following additional packages will be installed:
#6 9.948   binutils binutils-aarch64-linux-gnu binutils-common bzip2 ca-certificates
...<redacted>...
#6 12.91   readline-common rpcsvc-proto xz-utils zlib1g-dev
#6 12.92 The following packages will be upgraded:
#6 12.92   perl-base
#6 13.07 1 upgraded, 156 newly installed, 0 to remove and 5 not upgraded.
#6 13.07 Need to get 113 MB of archives.
#6 13.07 After this operation, 445 MB of additional disk space will be used.
#6 13.07 Get:1 http://deb.debian.org/debian bookworm/main arm64 perl-base arm64 5.36.0-7+deb12u1 [1478 kB]
#6 13.30 Get:2 http://deb.debian.org/debian bookworm/main arm64 perl-modules-5.36 all 5.36.0-7+deb12u1 [2815 kB]
#6 13.70 Get:3 http://deb.debian.org/debian bookworm/main arm64 libgdbm6 arm64 1.23-3 [70.9 kB]
#6 156.5 Setting up python3-venv (3.11.2-1+b1) ...
...<redacted>...
#6 156.7 Processing triggers for ca-certificates (20230311) ...
#6 156.7 Updating certificates in /etc/ssl/certs...
#6 158.4 0 added, 0 removed; done.
#6 158.4 Running hooks in /etc/ca-certificates/update.d...
#6 158.5 done.
#6 DONE 161.7s

#7 [3/7] ADD ./app/ /app
#7 DONE 6.6s

#8 [4/7] RUN python3 -m venv /app/quizenv
#8 DONE 17.7s

#9 [5/7] RUN . /app/quizenv/bin/activate && pip3 install -r /app/requirements.txt
#9 3.698 Collecting Flask>=2.0.0
#9 3.883   Downloading flask-3.0.0-py3-none-any.whl (99 kB)
#9 4.286      ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 99.7/99.7 kB 228.0 kB/s eta 0:00:00
...<redacted>...
#9 30.35 Successfully installed Flask-3.0.0 Jinja2-3.1.2 MarkupSafe-2.1.3 Werkzeug-3.0.1 blinker-1.7.0 click-8.1.7 flask_healthz-1.0.1 grpcio-1.60.0 grpcio-tools-1.60.0 gunicorn-21.2.0 itsdangerous-2.1.2 packaging-23.2 protobuf-4.25.1
#9 DONE 32.4s

#10 [7/7] RUN chown -R 1000480000 /app
#10 DONE 11.0s

#11 exporting to image
#11 exporting layers
#11 exporting layers 22.3s done
#11 writing image sha256:35811cdc7c7616c7c825fb8cc9901f2378c95ec0f60ae087aac1f8dcefb25f43
#11 writing image sha256:35811cdc7c7616c7c825fb8cc9901f2378c95ec0f60ae087aac1f8dcefb25f43 0.2s done
#11 naming to registry.k3s.kippel.de:5000/development/flask/simple-quiz:v0.9
#11 naming to registry.k3s.kippel.de:5000/development/flask/simple-quiz:v0.9 0.3s done
#11 DONE 22.8s

The push refers to repository [registry.k3s.kippel.de:5000/development/flask/simple-quiz]
d3347c231307: Pushed 
8882caf5885e: Pushed 
504284a508c8: Pushed 
9aea55af74f3: Pushed 
0cfc443021d9: Layer already exists 
e9d9a56c6bc5: Pushed 
73dca680fc18: Layer already exists 
v0.9: digest: sha256:af6f2e247c87843c2440bdaefd71068ed74266f04f7191372179ca68a58d2669 size: 1792
```

## Installing the service with helm<a name="helminstall"></a>

The 'install.sh' script is a wrapper around helm that also supports 'upgrade' and 'delete' operations. For a simple first-time installation you could just run :

```sh
helm install simple-quiz --namespace simple-quiz --create-namespace -f ./helm/values.yaml ./helm
```

The installation log is brief :

```sh
cd ./kubernetes
./install.sh

WARNING: Kubernetes configuration file is group-readable. This is insecure. Location: /etc/rancher/k3s/k3s.yaml
WARNING: Kubernetes configuration file is world-readable. This is insecure. Location: /etc/rancher/k3s/k3s.yaml
NAME: simple-quiz
LAST DEPLOYED: Tue Dec 12 19:03:09 2023
NAMESPACE: simple-quiz
STATUS: deployed
REVISION: 1
TEST SUITE: None
```

Let's do a quick sanity check :

```sh
# helm -n simple-quiz list
NAME       	NAMESPACE  	REVISION	UPDATED                                	STATUS  	CHART          	APP VERSION
simple-quiz	simple-quiz	1       	2023-12-12 19:03:09.395572272 +0100 CET	deployed	simple-quiz-0.9	v0.9       
```

Looking good.


## Verifying service sanity<a name="verifyservice"></a>

If you are interested, list the kubernetes objects installed by helm :

```sh
# kubectl -n simple-quiz get all
NAME                             READY   STATUS    RESTARTS   AGE
pod/simple-quiz-7f8cbb56-8gskz   1/1     Running   0          104s

NAME                  TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
service/simple-quiz   ClusterIP   10.43.216.58   <none>        8000/TCP   104s

NAME                          READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/simple-quiz   1/1     1            1           104s

NAME                                   DESIRED   CURRENT   READY   AGE
replicaset.apps/simple-quiz-7f8cbb56   1         1         1       104s

# kubectl -n simple-quiz get ingressroute 
NAME          AGE
simple-quiz   2m34s
```

Let's peek at the application log from the simple-quiz pod :

```sh
# kubectl logs -n simple-quiz pod/simple-quiz-7f8cbb56-8gskz

[2023-12-12 18:03:53 +0000] [8] [DEBUG] Current configuration:
  config: ./gunicorn.conf.py
...<redacted>...
  strip_header_spaces: False
[2023-12-12 18:03:53 +0000] [8] [INFO] Starting gunicorn 21.2.0
[2023-12-12 18:03:53 +0000] [8] [DEBUG] Arbiter booted
[2023-12-12 18:03:53 +0000] [8] [INFO] Listening at: http://0.0.0.0:8000 (8)
[2023-12-12 18:03:53 +0000] [8] [INFO] Using worker: sync
[2023-12-12 18:03:53 +0000] [9] [INFO] Booting worker with pid: 9
[2023-12-12 18:03:53 +0000] [8] [DEBUG] 1 workers
```

Ok. gunicorn seems to have started the application successfully.


## Accessing the application<a name="applicationui"></a>

Our path-based ingress route should give us access via

http://ingress.k3s.kippel.de/simple-quiz/

Let's try.

```sh
# curl -v http://ingress.k3s.kippel.de/simple-quiz/
*   Trying 192.168.100.150:80...
* Connected to ingress.k3s.kippel.de (192.168.100.150) port 80 (#0)
> GET /simple-quiz/ HTTP/1.1
> Host: ingress.k3s.kippel.de
> User-Agent: curl/7.74.0
> Accept: */*
> 
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK
< Content-Length: 1114
< Content-Type: text/html; charset=utf-8
< Date: Tue, 12 Dec 2023 18:11:15 GMT
< Server: gunicorn
< 
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="stylesheet" href="//maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css">
    <title>Quiz - Python</title>
 </head>
 <body>
    <div class="navbar navbar-default">
    <div class="container">
      <div class="navbar-header">
        <div class="navbar-brand"> <a href="/simple-quiz">Simple Quiz</a></div>
      </div>
      <ul class="nav navbar-nav">
        <li><a href="/simple-quiz/questions/add">Create Question</a></li>
        <li><a href="/simple-quiz/client/">Take Test</a></li>
      </ul>
    </div>
    </div>
    <div class="container">
    <h1>Welcome to the Simple Quiz</h1>
    <div class="jumbotron">
      <p>Welcome to the Simple Quiz where you can create a question, take a test or review feedback</p>
    </div>
    <h3 class="col-md-4"> <a href="/simple-quiz/questions/add">Create Question</a></h3>
    <h3 class="col-md-4"> <a href="/simple-quiz/client/">Take Test</a></h3>
    </div>
</body>
* Connection #0 to host ingress.k3s.kippel.de left intact
```

Works flawlessly. Trying the same in any browser with access to our network presents the splash screen.<br/>

![Simple Quiz Splashscreen]({{ "/assets/images/2023-12-12-rolling-our-own-docker-images/simple-quiz-splashscreen.png" | relative_url }}){:width="700px"}

I will leave figuring out the mechanics of the application as an exercise for the reader.<br/>

A slightly more challenging task is this :

> Use VS Code for remote debugging of the application. That requires you to add an additional exposed debug port to the service. Use either kubectl proxy to temporarily forward this debug port into the network where you are running VS Code or define a MetalLB Load Balancer service that exposes the debug port over a dedicated ip address (i would prefer the latter).<br/><br/>
> Rebuild the application image to start the application in debug mode :<br/>
>> python3 -m debugpy --listen 0.0.0.0:13487 ./app/run_server.py

Let me know in the comments how you fared.

## Conclusion<a name="conclusion"></a>

We covered quite a bit of ground in our journey. In the next stretch i will look into a number of topics :

- Installing and customizing <b>gitea</b> as a git replacement.
- Finding and installing an in-cluster docker-build capability.
- Installing and customizing <b>Jenkins</b> to integrate gitea and docker-build.

Stay tuned !
