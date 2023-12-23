---
layout: post
title: "Installing Gitea"
date: 2023-12-23
categories: kubernetes
tags: git
description: >
  Install a self-hosted Git service. Git with a cup of tea
---
[<b>Gitea</b>](https://about.gitea.com/) is an excellent and easy to use version control system. Today we are going to install it in our cluster as the next step in creating a build pipeline for our container images.

- Table of Contents
{:toc .large-only}

## Prerequisite - Installing Postgres

The [<b>bitnami</b>](https://bitnami.com/stack/gitea/virtual-machine) Gitea images do not support the arm64 architecture, so we have to install Postgres on our own. To create the Kubernetes objects we require the .yaml files to feed to kubectl. An easy way to get them is to use helm and let it do a dry run installation :

- download the helm chart and unpack the tar ball into a local directory
- do a dry-run installation to collect the .yaml files

~~~sh
helm fetch gitea-charts/gitea --untar=true --untardir=.
helm install --dry-run gitea -f ./values.yaml  . > ./gitea-dry-run-log.txt
~~~

Now we can lift the .yaml files from `./gitea-dry-run-log.txt`.

We need a password for Postgres. Security is not really a concern for this installation, so let's just make it a little harder for my kids.

~~~sh
#File: 'mkpgpass.sh'
#!/bin/bash
pwd=$(echo "my postgres password" | sha256sum | sed -ne 's/^\(.\{16\}\).*$/\1/ p')
echo "Hashed Password : $pwd"
echo "Password base64 :" $(echo -n $pwd | base64 -w0)
exit 0
~~~

~~~sh
Hashed Password : c866b34bd2d7cabd
Password base64 : Yzg2NmIzNGJkMmQ3Y2FiZA==
~~~

The base64-encoded *password* goes into the postgres secret.

~~~yaml
#File: 'postgres-secret.yaml'
apiVersion: v1
kind: Secret
metadata:
  namespace: gitea
  name: gitea-postgres-secret
type: Opaque
data:
  # postgrespass
  password: Yzg2NmIzNGJkMmQ3Y2FiZA==
~~~

The [database create statements](https://docs.gitea.com/next/installation/database-prep) are straight from the Gitea documentation. We collect them in a config map and inject that as the file `init-gitea.sh` in the volume `/docker-entrypoint-initdb.d/` of the stateful set.

~~~yaml
#File: 'postgres-configmap.yaml'
apiVersion: v1
kind: ConfigMap
metadata:
  name: gitea-initdb
  namespace: gitea
  labels:
    app: gitea-postgres
data:
  init-gitea.sh: |
    echo "Creating 'gitea' database..."
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOF
      CREATE ROLE gitea WITH LOGIN PASSWORD 'gitea';
      CREATE DATABASE gitea WITH OWNER gitea TEMPLATE template0 ENCODING UTF8 LC_COLLATE 'en_US.UTF-8' LC_CTYPE 'en_US.UTF8';
      \connect gitea;
      CREATE SCHEMA gitea;
      GRANT ALL ON SCHEMA gitea TO gitea;
      ALTER USER gitea SET search_path=gitea;
    EOF
    echo "Created database."
~~~


At the bottom of the stateful set definition we have to decide how much memory we want to set aside for the persisten volume claim
I decided that 5 GB was enough for me.

~~~yaml
#File: 'postgres-statefulset.yaml'
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: gitea-postgres
  namespace: gitea
spec:
  selector:
    matchLabels:
      app: gitea-postgres
  serviceName: gitea-postgres
  template:
    metadata:
      labels:
        app: gitea-postgres
    spec:
      containers:
      - name: postgres
        image: postgres:14
        env:
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: gitea-postgres-secret
              key: password
        - name: PGDATA
          value: /var/lib/postgresql/data/pgdata
        volumeMounts:
        - name: pgdata
          mountPath: /var/lib/postgresql/data
        - name: gitea-initdb
          mountPath: /docker-entrypoint-initdb.d/
      volumes:
        - name: gitea-initdb
          configMap:
            name: gitea-initdb
  volumeClaimTemplates:
  - metadata:
      name: pgdata
    spec:
      storageClassName: longhorn
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 5Gi
~~~


The Postgres instance and Gitea will be living in the same namespace so a service with a cluster ip-address is sufficient to establish connectivity.

~~~yaml
#File: 'postgres-service.yaml'
apiVersion: v1
kind: Service
metadata:
  name: gitea-postgres
  namespace: gitea
  labels:
    app: gitea-postgres
spec:
  type: ClusterIP
  ports:
  - port: 5432
  selector:
    app: gitea-postgres
~~~

Now that we have the .yaml files complete, we can kick off the creation of the Postgres service.

~~~sh
File: 'install-postgres.sh'
#!/bin/bash

kubectl create namespace gitea

dir=$(dirname ${0})
kubectl -n gitea apply -f $dir/postgres-secret.yaml
kubectl -n gitea apply -f $dir/postgres-configmap.yaml
kubectl -n gitea apply -f $dir/postgres-statefulset.yaml
kubectl -n gitea apply -f $dir/postgres-service.yaml

exit 0
~~~

If everything goes well, we should see 4 pods coming up :
~~~sh
$ kubectl -n gitea get pods
NAME                                              READY   STATUS
pod/gitea-postgres-0                              1/1     Running
pod/gitea-postgresql-ha-pgpool-554fb9b4cc-dl4lv   1/1     Running
pod/gitea-postgresql-ha-postgresql-0              1/1     Running
pod/gitea-postgresql-ha-postgresql-2              1/1     Running
pod/gitea-postgresql-ha-postgresql-1              1/1     Running
~~~

Having a quick look at the logs should return output similar to this :

~~~sh
#kubectl -n gitea logs gitea-postgresql-ha-pgpool-554fb9b4cc-dl4lv
pgpool 19:21:37.75 
pgpool 19:21:37.76 Welcome to the Bitnami pgpool container
pgpool 19:21:37.76 Subscribe to project updates by watching https://github.com/bitnami/containers
pgpool 19:21:37.77 Submit issues and feature requests at https://github.com/bitnami/containers/issues
pgpool 19:21:37.78 
pgpool 19:21:37.78 INFO  ==> ** Starting Pgpool-II setup **
... redacted ...

#kubectl -n gitea logs gitea-postgres-0
PostgreSQL Database directory appears to contain a database; Skipping initialization
2023-12-21 19:22:05.399 UTC [1] LOG:  starting PostgreSQL 14.10 (Debian 14.10-1.pgdg120+1) on aarch64-unknown-linux-gnu, compiled by gcc (Debian 12.2.0-14) 12.2.0, 64-bit
2023-12-21 19:22:05.401 UTC [1] LOG:  listening on IPv4 address "0.0.0.0", port 5432
... redacted ...

# kubectl -n gitea logs gitea-postgresql-ha-postgresql-0
postgresql-repmgr 19:21:46.91 
postgresql-repmgr 19:21:46.98 Welcome to the Bitnami postgresql-repmgr container
postgresql-repmgr 19:21:47.02 Subscribe to project updates by watching https://github.com/bitnami/containers
postgresql-repmgr 19:21:47.04 Submit issues and feature requests at https://github.com/bitnami/containers/issues
postgresql-repmgr 19:21:47.06 
postgresql-repmgr 19:21:47.24 INFO  ==> ** Starting PostgreSQL with Replication Manager setup **
... redacted ...
~~~

## Installing Gitea

We let helm do the actual installation. The value.yaml is below. The only item to watch out for is postgresql.enabled. For obvious reasons this has to be set to **false**. 

~~~yaml
#File: 'gitea-values.yaml'
# Disable memcached; Gitea will use an internal 'memory' cache.
memcached:
  enabled: false

# Disable postgresql since it is already installed.
postgresql:
  enabled: false

# The Gitea docs recommend this: Share the IP for HTTP and SSH.
service:
  ssh:
    annotations:
      metallb.universe.tf/allow-shared-ip: gitea

# be careful to pick the right hostname.
gitea:
  config:
    server:
      DOMAIN: git.k3s.kippel.de
    database:
      DB_TYPE: postgres
      HOST: gitea-postgres.gitea.svc.cluster.local:5432
      USER: gitea
      PASSWD: gitea
      NAME: gitea
      SCHEMA: gitea
~~~

~~~sh
File: 'install-gitea.sh'
#!/bin/bash

dir=$(dirname ${0})

helm repo add gitea-charts https://dl.gitea.io/charts/
helm repo update
helm install gitea gitea-charts/gitea --namespace gitea --create-namespace --values $dir/gitea-values.yaml

kubectl -n gitea apply -f $dir/gitea-loadbalancer.yaml

exit 0
~~~


### Upgrading Gitea

Upgrading Gitea when a new release is published is a straightforward exercise. Just leave it to Helm.

~~~sh
# helm repo update

# helm upgrade gitea gitea-charts/gitea --namespace gitea --values gitea-values.yaml

Release "gitea" has been upgraded. Happy Helming!
NAME: gitea
LAST DEPLOYED: Sat Nov  4 10:28:58 2023
NAMESPACE: gitea
STATUS: deployed
REVISION: 2
NOTES:
1. Get the application URL by running these commands:
  echo "Visit http://127.0.0.1:3000 to use your application"
  kubectl --namespace gitea port-forward svc/gitea-http 3000:3000
~~~

## Exposing Gitea with a MetalLB Load Balancer Service

I want to use http for the Web-UI and ssh for the git client, so i am going to expose ports 80 and 22 in the load balancer service.

~~~yaml
#File: 'gitea-loadbalancer.yaml'
apiVersion: v1
kind: Service
metadata:
  labels:
    app: gitea
  name: gitea
  namespace: gitea
spec:
  type: LoadBalancer
  ports:
  - name: gitea-http
    port: 80
    protocol: TCP
    targetPort: 3000
  - name: gitea-ssh
    port: 22
    protocol: TCP
    targetPort: 2222
  selector:
    app: gitea
~~~

After applying the .yaml file with kubectl i took the external ip address and added it to `/etc/dnsmasq.hosts` of my dnsdhcp server.

~~~sh
#kubectl -n gitea get svc/gitea
NAME   TYPE           CLUSTER-IP      EXTERNAL-IP       PORT(S)                     AGE
gitea  LoadBalancer   10.43.231.147   192.168.100.155   80:32343/TCP,22:30524/TCP   0d
~~~

Opening the URL gives me the Gitea logon screen.

![Gitea Splashscreen]({{ "/assets/images/2023-12-23-installing-gitea/gitea-splashscreen.png" | relative_url }}){:width="700px" .centered}

Gitea Splashscreen
{:.figcaption}

Creating a user account and configuring it for ssh access is similar to Github, no surprises there. After creating a new repository, pushing an existing directory was successful.

~~~sh
git init
git add -A .
git commit -m "first commit"
git remote add origin git@git.k3s.kippel.de:axel/swagger-editor.git
git push -u origin master

git push -u origin master
Enumerating objects: 3, done.
Counting objects: 100% (3/3), done.
Writing objects: 100% (3/3), 203 bytes | 203.00 KiB/s, done.
Total 3 (delta 0), reused 0 (delta 0), pack-reused 0
remote: . Processing 1 references
remote: Processed 1 references in total
To git.k3s.kippel.de:axel/swagger-editor.git
 * [new branch]      master -> master
branch 'master' set up to track 'origin/master'.
~~~

## Conclusion

The pace is picking up. With a professional version management service like Gitea we can do all kind of things :

- docker builds from the repo
- use webhooks on commit for triggering follow-up activities

The Interesting Times Gang would be happy. I hope so are you.

Stay tuned !
