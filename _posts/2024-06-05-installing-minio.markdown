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


<br/><br/>
Stay tuned.
