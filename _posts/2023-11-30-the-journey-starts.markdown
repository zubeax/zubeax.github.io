---
layout: post
title: "The Journey Starts"
date: 2023-11-30
categories: kubernetes raspberrypi
---

After initially being quite excited about the possibilities offered by [Kubernetes}(https://kubernetes.io/) on [GCP](https://cloud.google.com/),
i was quickly frustrated by the fact that operations kept us at arms length from playing 
on the command line.
Turns out Google has to earn money, so all the resources have to be paid for. On top of that
every change is going through Terraform. It was quite disenchanting.

While looking for ways to set up an environment that i could manage on my own i came across 
a number of blogs where people deployed [k3s](https://k3s.io/) (a bare-metal kubernetes distribution) on 
Raspberry Pi clusters in all shapes and sizes.
I had used Raspberry PIs for a number of projects throughout my house over the last years,
so i decided to give it a try.
Even if i did not require an HA configuration with 99.999% availability i still wanted a decent case, a fan and and no wires all over the place.

This is what i came up with.

![Raspberry Pi Kubernetes Cluster]({{ "/assets/Raspberry Pi Kubernetes Cluster.png" | relative_url }})

A 4-node [Raspberry Pi 4](https://www.raspberrypi.com/products/raspberry-pi-4-model-b/) cluster.
Each cluster node has a 500 GB SSD attached via an SATA/USB 3.0 adapter that serves both as OS disk as well as storage medium for Kubernetes persistent volumes. 
Power is provided by a 5-port USB-C hub. Connectivity is managed by a 5-port switch.
So i have 2 220V connections and 1 Ethernet patch cable.

If you can do better than that, be my guest.