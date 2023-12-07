---
layout: post
title: "Building a Raspberry Pi Cluster"
date: 2023-12-06
categories: cluster raspberrypi
tags: cluster raspberrypi
---
In this article I am going to install and configure Raspbian OS on the cluster nodes.

I assigned the cluster nodes hostnames in the range rbpic0n[1-4] :

![Cluster Schematic]({{ "/assets/images/2023-12-06-build-pi-cluster/cluster-schematic.png" | relative_url }})

rbpic0n1 is designated as the master node, the rest will become client nodes.

<br/><br/>
## Installing the OS

I used the Raspberry Pi Imager to flash the OS on all 4 SSDs. I connected the SATA/USB Adapters to a USB-Hub attached to my workstation.

The configuration options would cover 

-   hostname
-   keyboard layout
-   timezone
-   non-root account with an ssh public key of my choice


![Splash Screen]({{ "/assets/images/2023-12-06-build-pi-cluster/pi-imager-splash-screen.png" | relative_url }}){:width="700px"}
<br/>
![General Settings]({{ "/assets/images/2023-12-06-build-pi-cluster/pi-imager-general.png" | relative_url }}){:height="400px"} ![SSH Settings]({{ "/assets/images/2023-12-06-build-pi-cluster/pi-imager.ssh-config.png" | relative_url }}){:height="400px"}

<br/><br/>
### Configuring for USB Boot

The data transfer rates to an SSD are about 3 times higher than those to an SD Card.

```bash
# dd if=/dev/random of=/mnt/sdcard2/tmp/murx bs=$((1024*1024)) count=512
512+0 records in
512+0 records out
536870912 bytes (537 MB, 512 MiB) copied, 18.0773 s, 29.7 MB/s
```

```bash
# dd if=/dev/random of=/tmp/murx bs=$((1024*1024)) count=512
512+0 records in
512+0 records out
536870912 bytes (537 MB, 512 MiB) copied, 7.23104 s, 74.2 MB/s
```

 So i decided to configure the cluster nodes to also boot from SSD not just use it for data storage.

This step can't be executed on the SSDs. We have to boot each node and execute the <code><b>rpi-eeprom-config</b></code> utility program. I decided to sacrifice 4 SD cards to boot from and leave them in each node to have a fallback in case an SSD should fail.

Booting each node from the same SD card might be a cheaper option.

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

The boot order 0xf14 stands for : (usb, sdcard, repeat). Repeat this step for all 4 nodes.

<br/><br/>
### Resizing the disk partitions

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


 ┌───────────────────────────────────────────────────────────────────┐
 │  Partition type: Linux (83)                                       │
 │ Filesystem UUID: dfdd8a7e-e593-4c2d-b3e0-684a50189d8c             │
 │Filesystem LABEL: data                                             │
 │      Filesystem: ext4                                             │
 │      Mountpoint: /mnt/sda3 (mounted)                              │
 └───────────────────────────────────────────────────────────────────┘
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

Now we grab the PARTUUID of our new partition /dev/sda3

```bash
# blkid
/dev/mmcblk0p1: LABEL_FATBOOT="bootfs" LABEL="bootfs" UUID="0B22-2966" BLOCK_SIZE="512" TYPE="vfat" PARTUUID="a48c1955-01"
/dev/mmcblk0p2: LABEL="rootfs" UUID="3ad7386b-e1ae-4032-ae33-0c40f5ecc4ac" BLOCK_SIZE="4096" TYPE="ext4" PARTUUID="a48c1955-02"
/dev/sda1: LABEL_FATBOOT="bootfs" LABEL="bootfs" UUID="0B22-2966" BLOCK_SIZE="512" TYPE="vfat" PARTUUID="2245eb21-01"
/dev/sda2: LABEL="rootfs" UUID="3ad7386b-e1ae-4032-ae33-0c40f5ecc4ac" BLOCK_SIZE="4096" TYPE="ext4" PARTUUID="2245eb21-02"
/dev/sda3: LABEL="data" UUID="dfdd8a7e-e593-4c2d-b3e0-684a50189d8c" BLOCK_SIZE="4096" TYPE="ext4" PARTUUID="2245eb21-03"
```

and add it to /etc/fstab

```bash
proc                       /proc        proc    defaults                                            0 0
PARTUUID=2245eb21-01       /boot        vfat    defaults                                            0 2
PARTUUID=2245eb21-02       /            ext4    defaults,noatime                                    0 1
PARTUUID=2245eb21-03       /mnt/sda3    ext4    defaults,noatime                                    0 0
```

After completing these steps on all 4 nodes, we are now ready to start the entire cluster. 
The 5-port USB-C charger i use for a power supply is hidden in the case, so i use a switched powerstrip.

Let's see what happens when i push the switch.

<br/><br/>
### Preliminary Diagnostics

I use a standalone Raspberry Pi B to run <b>dnsmasq</b> for DHCP and DNS services. Let's look at dhcp.leases.

```bash
ssh dhcpdns 'cat /tmp/dhcp.leases' | grep -e 'rbpic0n[1-4]'
1701979039 d8:3a:dd:10:d1:37 192.168.100.24 rbpic0n3 01:d8:3a:dd:10:d1:37
1701979044 d8:3a:dd:10:d2:90 192.168.100.242 rbpic0n1 01:d8:3a:dd:10:d2:90
1701979043 d8:3a:dd:10:d1:eb 192.168.100.26 rbpic0n4 01:d8:3a:dd:10:d1:eb
1701979040 d8:3a:dd:10:d1:cb 192.168.100.37 rbpic0n2 01:d8:3a:dd:10:d1:cb
```

Looks good.

Let's check the mounted file systems.

```bash
$ clustercmd mount

=== rbpic0n1

/dev/sda2 on / type ext4 (rw,noatime)
/dev/sda3 on /mnt/sda3 type ext4 (rw,noatime,stripe=8191)
/dev/sda1 on /boot type vfat (rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=ascii,shortname=mixed,errors=remount-ro)

=== rbpic0n2

/dev/sda2 on / type ext4 (rw,noatime)
/dev/sda3 on /mnt/sda3 type ext4 (rw,noatime,stripe=8191)
/dev/sda1 on /boot type vfat (rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=ascii,shortname=mixed,errors=remount-ro)

=== rbpic0n3

/dev/sda2 on / type ext4 (rw,noatime)
/dev/sda3 on /mnt/sda3 type ext4 (rw,noatime,stripe=8191)
/dev/sda1 on /boot type vfat (rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=ascii,shortname=mixed,errors=remount-ro)

=== rbpic0n4

/dev/sda2 on / type ext4 (rw,noatime)
/dev/sda3 on /mnt/sda3 type ext4 (rw,noatime,stripe=8191)
/dev/sda1 on /boot type vfat (rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=ascii,shortname=mixed,errors=remount-ro)

```

All SSD partitions are there.

Last step. CPU temperatures :

```bash
$ clustercmd vcgencmd measure_temp

=== rbpic0n1

temp=40.4'C

=== rbpic0n2

temp=35.0'C

=== rbpic0n3

temp=37.9'C

=== rbpic0n4

temp=32.1'C
```

No sweat. When the fan got too loud for me while i had the case on my desk, i would switch it off.
Then temperatures rose up to 60 °C. That was without any load on the system, so i guess this is not the ceiling.
After i move the cluster to the basement, the fan will run continuously so temperature should not be a concern.


Now it is time to look into the installation of Kubernetes master and client nodes. I will cover this in my next blog.

Stay tuned !

<br/><br/><br/>
P.S. the <b>clustercmd</b> command i used above is part of a set of shell utility functions i use to manage the cluster.
At the current stage i don't want to spend the time to become familiar with Ansible, so i keep things simple.

```bash
clusternodes () 
{ 
    echo rbpic0n1 rbpic0n2 rbpic0n3 rbpic0n4
}

clustercmd () 
{ 
    [[ $# -eq 0 ]] && { 
        cat 0<&0 > /tmp/bufferedstdin
    };
    for pi in $(clusternodes);
    do
        echo -e "===\n=== ${pi}\n===\n";
        if [[ $# -eq 0 ]]; then
            ssh -o LogLevel=QUIET -t $pi < /tmp/bufferedstdin;
        else
            ssh -o LogLevel=QUIET -t $pi "$@";
        fi;
    done;
    echo -e "\n";
    rm -f /tmp/bufferedstdin
}
```