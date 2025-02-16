---
title: "Home Lab #1: Proxmox Post Install"
author: "fr3d"
url: "/home-lab-1/"
tags: ["homelab, proxmox, virtualization, terraform"]
date: 2024-02-13T00:30:00-04:00
draft: false
showToc: true
---

## Prerequisites

{{< callout type="info" >}}

- Familarity with Linux, Proxmox and Terraform
  {{< /callout >}}

## Intro

Hypervisors are a core part of building a home lab. Whether it is Proxmox, Hyper-V or even just VirtualBox, a hypervisor gives us a large arena to experiment and test our skills.

I use Proxmox at home and currently run a two node cluster, one on an old desktop and one on a NUC.

Ref: [Beelink S12](https://www.amazon.com/dp/B0C89TQ1YF?psc=1&ref=ppx_yo2ov_dt_b_product_details)

I've installed proxmox countless times and I find myself running the same commands over and over again. I will eventually automate more of the hardware portion but after getting Proxmox installed, I make the following configuration changes to hit the ground running:

{{% steps %}}

### Add a Admin user for the GUI

```bash
pveum user add admin@pve -comment "admin user"

pveum passwd admin@pve

pveum group add admin -comment "System Administrators"

pveum acl modify / -group admin -role Administrator

pveum user modify admin@pve -group admin

```

### Add sudo user on the Debian Host

```bash
adduser admin

usermod -aG sudo admin

passwd admin #change the admin account password

```

### Generate Proxmox API Token

```bash
 sudo pveum role add TerraformProv \
    -privs '''Datastore.AllocateSpace Datastore.Audit
              Pool.Allocate Sys.Audit Sys.Console
              Sys.Modify VM.Allocate VM.Audit
              VM.Clone VM.Config.CDROM VM.Config.Cloudinit
              VM.Config.CPU VM.Config.Disk VM.Config.HWType
              VM.Config.Memory VM.Config.Network VM.Config.Options
              VM.Migrate VM.Monitor VM.PowerMgmt SDN.Use SDN.Allocate SDN.Audit
            '''
 sudo pveum user add tf-user@pve

 sudo pveum aclmod / -user tf-user@pve -role TerraformProv

 sudo pveum user token add tf-user@pve terraform-provisioner --privsep 0

#Make sure to copy the API token displayed in the prompt and store it in a secure place.
#It's required to authenticate with the proxmox API.

#Token needed in provider config
#home-1 = xxxxxxxx-xxxxxxx-xxxxxx-xxxxxxxx

 sudo pveum aclmod / -token 'tf-user@pve!terraform-provisioner' -role TerraformProv

```

{{% /steps %}}

## Summary

These steps can help anyone get their Proxmox journey started. On a side note , I did not show how to secure SSH access for Proxmox. That is your homework!
