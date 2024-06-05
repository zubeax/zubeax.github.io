---
layout: post
title: "Installing Minio"
date: 2024-06-05
categories: [kubernetes]
description: >
  Installing the Minio object store
---
[MinIO](https://min.io/docs/minio/kubernetes/upstream/index.html) is an object storage solution that provides an AWS S3-compatible API plus a neat WebUI for managing 

![Minio Console]({{ "/assets/images/2024-06-05-installing-minio/Minio Console.png" | relative_url }})

A Screenshot of the Minio Object Store Console
{:.figcaption}

A self-hosted and -managed remote persistent storage solution is nice to have when box.net or Google Drive are out of the window 
for monetary, security or confidentiality reasons.<br/>
I had a similar use case in mind when i started looking at solutions i could run in my 
[Raspberry Pi k3s kubernetes cluster](https://blog.smooth-sailing.net/raspberrypi/2023-11-30-the-journey-begins/).

Minio consists of 2 architecture components that are installed in sequence.

![Minio-Architecture.png]({{ "/assets/images/2024-06-05-installing-minio/Minio-Architecture.png" | relative_url }})

- [Installation of Minio Operator](https://min.io/docs/minio/kubernetes/upstream/operations/installation.html)
- [Installation of a Minio Tenant](https://min.io/docs/minio/kubernetes/upstream/operations/deploy-manage-tenants.html)

I decided to install both components with helm (it is feasible to install the tenat from the operator, but i decided against that),
so in a prerequisite step we add the minio repo :

```bash
$ helm repo add minio-operator https://operator.min.io
"minio-operator" has been added to your repositories
```

Now we can check which version is available.

```bash
$ helm search repo minio-operator
NAME                         	CHART VERSION	APP VERSION	DESCRIPTION
minio-operator/minio-operator	4.3.7        	v4.3.7     	A Helm chart for MinIO Operator
minio-operator/operator      	5.0.15       	v5.0.15    	A Helm chart for MinIO Operator
minio-operator/tenant        	5.0.15       	v5.0.15    	A Helm chart for MinIO Operator
```

## Installation of Minio Operator

I prefer to have the helm charts available locally, so i usually fetch them, edit 'values.yaml' 
and then install from the local directory. Let's go and do that.

```bash
$ helm fetch minio-operator/operator --untar=true --untardir=.
operator/
├── Chart.yaml
├── README.md
├── templates
│   ├── console-clusterrolebinding.yaml
│   ├── console-clusterrole.yaml
│   ├── console-configmap.yaml
│   ├── console-deployment.yaml
│   ├── console-ingress.yaml
│   ├── console-secret.yaml
│   ├── console-serviceaccount.yaml
│   ├── console-service.yaml
│   ├── _helpers.tpl
│   ├── job.min.io_jobs.yaml
│   ├── minio.min.io_tenants.yaml
│   ├── NOTES.txt
│   ├── operator-clusterrolebinding.yaml
│   ├── operator-clusterrole.yaml
│   ├── operator-deployment.yaml
│   ├── operator-serviceaccount.yaml
│   ├── operator-service.yaml
│   ├── sts.min.io_policybindings.yaml
│   └── sts-service.yaml
└── values.yaml
```

I prefer to have the images for all applications i deploy to my deploy available in a local registry, so i had to update
the image source in 'values.yaml'. After that i did a clean helm install.

```bash
$ helm install --namespace minio-operator --create-namespace   operator -f ./values.yaml .

NAME: operator
LAST DEPLOYED: Tue May 21 20:15:34 2024
NAMESPACE: minio-operator
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
1. Get the JWT for logging in to the console:
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: console-sa-secret
  namespace: minio-operator
  annotations:
    kubernetes.io/service-account.name: console-sa
type: kubernetes.io/service-account-token
EOF
kubectl -n minio-operator get secret console-sa-secret -o jsonpath="{.data.token}" | base64 --decode

2. Get the Operator Console URL by running these commands:
  kubectl --namespace minio-operator port-forward svc/console 9090:9090
  echo "Visit the Operator Console at http://127.0.0.1:9090"
```

### Exposing the Minio Operator Console 

My standard procedure for exposing static services is to assign them a static IP address from my home network with a 
MetalLB LoadBalancer Service (i covered the installation [here](https://blog.smooth-sailing.net/kubernetes/k3s/2023-12-08-customizing-k3s/))
and add an ip-address/hostname entry to dnsmasq.hosts of the dnsmasq server serving my home network.
(I use ingress routes for services that i consider more ephemeral).

Here is the manifests file for the service.

```bash
apiVersion: v1
kind: Service
metadata:
  labels:
    app: minio-console-lb
  name: minio-console-lb
  namespace: minio-operator
spec:
  type: LoadBalancer
  ports:
  - name: minio-http
    port: 80
    protocol: TCP
    targetPort: 9090
  - name: minio-https
    port: 9443
    protocol: TCP
    targetPort: 9443
  selector:
    app.kubernetes.io/instance: operator-console
    app.kubernetes.io/name: operator
```

Access to the operator console requires an access token. That is retrieved from the secret 'console-sa-secret' that was 
deployed along with the rest. Token retrieval works as usual :

```bash
kubectl -n minio-operator get secret console-sa-secret -o jsonpath='{.data.token}' | base64 -d
eyJhbGciOiJSUzI1NiIs...DaIVLsEYCW5ww
```

For the moment we are done with the Minio Operator. Let's start with tenant installation.


## Installation of Minio Tenant

As for the operator, we fetch the tenant helm chart.

```bash
$ helm fetch minio-operator/tenant --untar=true --untardir=.
```

In 'values.yaml' i changed :
- the number of servers (2)
- the number of volumes per server (4)
- the volume size (5Gi)
- the storage class name (longhorn). 
(the ssd's attached to my cluster nodes are managed by [longhorn](https://blog.smooth-sailing.net/kubernetes/k3s/2023-12-08-customizing-k3s/))

```yaml
tenant:
  name: miniok3s
  image:
    repository: registry.k3s.kippel.de:5000/base/minio/minio
    tag: RELEASE.2024-05-01T01-11-10Z
    pullPolicy: IfNotPresent
  imagePullSecret: { }
  scheduler: { }
  configuration:
    name: miniok3s-env-configuration
  pools:
    - servers: 2
      name: pool-0
      volumesPerServer: 4
      size: 5Gi
      storageClassName: longhorn
```

This gives me 2 servers (i.e. tenant pods) managing 4 volumes of 5GB each supplying me with a total of 40 GB of storage.

```bash
```


<br/><br/>
Stay tuned.
