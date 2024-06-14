---
layout: post
title: "The Journey Begins"
date: 2023-11-30
category: topics
tags: raspberrypi
description: >
  How did i end up thinking about a Kubernetes cluster of my own ?
---
After initially being quite excited about the possibilities offered by [Kubernetes](https://kubernetes.io/) on [GCP](https://cloud.google.com/),
i was quickly frustrated by the fact that operations kept us at arm's length from playing on the Cloud Console (aka command line).<br/>
Turns out Google has to earn money, so all resources have to be paid for. On top of that
every change is going through [Terraform](https://www.terraform.io/) in a Gitops pipeline. It was quite disenchanting.

While looking for ways to set up an environment that i could manage on my own, i came across 
a number of blogs where people deployed [k3s](https://k3s.io/) (a bare-metal kubernetes distribution) on 
Raspberry Pi clusters in all shapes and sizes. I had used Raspberry PIs for a number of projects throughout my house over the years,
so i decided to give it a try.
<br/>
Even if i did not require an HA configuration with 99.999% availability i still wanted a decent case, a fan, and no wires all over the place.

This is what i came up with.

![Raspberry Pi Kubernetes Cluster]({{ "/assets/images/Raspberry Pi Kubernetes Cluster.png" | relative_url }})

The assembled cluster sitting on a desk
{:.figcaption}

A 4-node [Raspberry Pi 4](https://www.raspberrypi.com/products/raspberry-pi-4-model-b/) cluster.<br/>
Each cluster node has a 500 GB SSD attached via a SATA/USB 3.0 adapter. The SSDs serve both as OS disks as well as storage medium for Kubernetes persistent volumes. The price-tag was about 500 EUR. A decent price for 16 cores, 32 GB of RAM and 2 TB of disk space.<br/>
Power is provided by a 5-port USB hub. Connectivity is managed by a 5-port switch. So i have 2 220V connections and 1 Ethernet patch cable. Good enough to get started.<br/>
Power consumption is between 15 to 20 W. Running the cluster 24x7 amounts to about 70 EUR/year at 0.4 EUR/kWh. Compared to the annual 1400 EUR bill for an Intel Tower with a 400 W power supply this is quite a bargain.<br/>
<br/>
In this series of blogs i will cover my journey of turning this gadget into a useful member of my household.
<br/><br/>
Stay tuned.
  