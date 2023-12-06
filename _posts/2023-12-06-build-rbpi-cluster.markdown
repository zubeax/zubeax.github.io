---
layout: post
title: "Building a Raspberry Pi Cluster"
date: 2023-12-06
categories: cluster raspberrypi
tags: cluster raspberrypi
---
In this article we are going to install and configure the Raspbian OS on the cluster nodes.

I assigned the cluster nodes hostnames in the range rbpic0n[1-4] :

[Cluster Schematic]({{ "/assets/images/2023-12-06-build-pi-cluster/cluster-schematic.png" | relative_url }})

## Installing the OS

I used the Raspberry Pi Imager to flash the OS on all 4 SSDs. Connect the SATA/USB Adapters to a USB-Hub attached
to my workstation.

[Splash Screen]({{ "/assets/images/2023-12-06-build-pi-cluster/pi-imager-splash-screen.png" | relative_url }})
[General Settings]({{ "/assets/images/2023-12-06-build-pi-cluster/pi-imager-general.png" | relative_url }})
[SSH Settings]({{ "/assets/images/2023-12-06-build-pi-cluster/pi-imager.ssh-config.png" | relative_url }})


## Configure for USB Boot

This step can't be executed on the SSDs. We have to boot each node and execute the <code><b>rpi-eeprom-config</b></code> utility program. I decided to sacrifice 4 SD cards to boot from and leave them in each node to have a fallback in case an SSD should fail.

Booting each node from the same SD card is a cheapter option.

After the node is up, open an ssh connection. Then perform the 2 steps below.

<b>Step 1</b> : Verify that the boot loader is recent.

```bash
# rpi-eeprom-update
BOOTLOADER: up to date
   CURRENT: Wed 11 Jan 17:40:52 UTC 2023 (1673458852)
    LATEST: Wed 11 Jan 17:40:52 UTC 2023 (1673458852)
   RELEASE: default (/lib/firmware/raspberrypi/bootloader/default)
            Use raspi-config to change the release.

  VL805_FW: Using bootloader EEPROM
     VL805: up to date
   CURRENT: 000138c0
    LATEST: 000138c0
```

<b>Step 2</b> : Set the boot order.

```bash
root@rbpic0n1:~ # rpi-eeprom-config --edit
[all]
BOOT_UART=0
WAKE_ON_GPIO=1
POWER_OFF_ON_HALT=0
NET_INSTALL_ENABLED=0
BOOT_ORDER=0xf14
```

The boot order to 0xf14 stands for : (usb, sdcard, repeat). Repeat this step for all 4 nodes.


## Resize the disk partitions

I wanted to set aside a separate partition to be managed by a Kubernetes storage manager so i resized the root partition to 60G :

```bash
resize2fs /dev/sda2 60G
```

then i used <b>cfdisk</b> to create a new partition in the reclaimed space.

```bash
                                               Disk: /dev/sda
                          Size: 465.76 GiB, 500107862016 bytes, 976773168 sectors
                                     Label: dos, identifier: 0x2245eb21

    Device          Boot             Start           End       Sectors       Size     Id Type
    /dev/sda1                         8192        532479        524288       256M      c W95 FAT32 (LBA)
    /dev/sda2                       532480     126361599     125829120        60G     83 Linux
>>  /dev/sda3                    126361600     976773119     850411520     405.5G     83 Linux              


 ┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
 │  Partition type: Linux (83)                                                                            │
 │ Filesystem UUID: dfdd8a7e-e593-4c2d-b3e0-684a50189d8c                                                  │
 │Filesystem LABEL: data                                                                                  │
 │      Filesystem: ext4                                                                                  │
 │      Mountpoint: /mnt/sda3 (mounted)                                                                   │
 └────────────────────────────────────────────────────────────────────────────────────────────────────────┘
       [Bootable]  [ Delete ]  [ Resize ]  [  Quit  ]  [  Type  ]  [  Help  ]  [  Write ]  [  Dump  ]
```


Finally i formatted this partition into an ext4 file system.

```bash
mkfs.ext4 /dev/sda3
```

Each of the SSDs attached to the cluster nodes now looks similar to this :

```bash
# sfdisk -l /dev/sda
Disk /dev/sda: 465.76 GiB, 500107862016 bytes, 976773168 sectors
Disk model: ASM1153USB3.0TOS
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 33553920 bytes
Disklabel type: dos
Disk identifier: 0x2245eb21

Device     Boot     Start       End   Sectors   Size Id Type
/dev/sda1            8192    532479    524288   256M  c W95 FAT32 (LBA)
/dev/sda2          532480 126361599 125829120    60G 83 Linux
/dev/sda3       126361600 976773119 850411520 405.5G 83 Linux
```
