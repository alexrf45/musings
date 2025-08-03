---
title: "Docker Course"
date: 2023-05-22
draft: false
summary: "Basic Fundamentals of Docker"
---

# Section 1: Docker Fundamentals

## What is Docker?

- Docker is an open platform for developing, shipping, and running applications using what's called containers and container images.
- Docker operates through the use of Linux Capabilities
- [man pages Linux capabilities](https://man7.org/linux/man-pages/man7/capabilities.7.html)
- [Linux Capabilities Explained](https://www.schutzwerk.com/en/blog/linux-container-capabilities/)
  - Linux divides the privileges traditionally associated with superuser into distinct units, known as _capabilities_, which can be independently enabled and
    disabled. Capabilities are a per-thread attribute.
    - Docker uses Linux capabilities "under the hood" to build,run and operate containers
      - Capabilities can be set at build time , run time and modified as needed
      - Traditionally containers use the **CAP_SETFCAP** flag at minimum to map a new user namespace for the container
        - User namespaces isolate security-related identifiers and
          attributes, in particular, user IDs and group IDs

## Docker Components

1. Docker Daemon: Listens for Docker API requests and manages Docker objects such as images, containers, networks, and volumes. A daemon can also communicate with other daemons to manage Docker services.
   1. Listens remotely by default on port 2375 (unencrypted) or 2376 (encrypted)
2. Docker Client: The docker cli uses the Docker API to communicate with the Docker Daemon and issue commands such as `run`, `build` `inspect`
   1. Package manager, binary or even container image for automated pipelines
3. Docker Registry: A Docker registry stores Docker images. Docker Hub is a public registry that anyone can use, and Docker looks for images on Docker Hub by default. You can even run your own private registry.
   1. Private registry listens on port 5000 by default
   2. Public registries are somewhat secure
   3. Registries can be hosted on prem or cloud, based off a pipeline

# Section 2: Docker Use Cases

1. "Dependency Hell" - Development Environment
2. Repeatable environment/configuration pipeline
3. Micro-services architecture
4. Software Testing

# Section 3: Docker Install

Ref: <https://github.com/docker/docker-install>

## Method #1: Docker Install Script (Recommended)

```bash
git clone https://github.com/docker/docker-install.git && cd docker-install.git
&& sh get-docker.sh

or YOLO

curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

sudo usermod -aG docker $USER

sudo docker run hello-world

log out and log back in


```

- This method also installs docker-buildx and docker-compose!!

## Method #2: Package Manager

\*\* all of this can be in a simple shell script and ran as `chmod +x docker.sh && ./docker.sh`

```bash
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done


sudo apt-get update

sudo apt-get install ca-certificates curl

sudo install -m 0755 -d /etc/apt/keyrings

sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc

sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo docker run hello-world

sudo usermod -aG docker $USER

log out and log back in

```

- This method tends to install a stable and older version of Docker. Reliable for most use cases

# Section 4: Docker Commands

## `docker pull`

### Pull specified image tag

```bash
docker pull ubuntu:24.10 debian:latest

```

### Pull latest Image

```bash
docker pull apline:latest

```

## `docker image`

### Example 1

```
 ~  $ docker image ls
REPOSITORY                    TAG            IMAGE ID       CREATED        SIZE
fonalex45/aegis               latest         6ec09f33a9a5   42 hours ago   5.91GB
fonalex45/aegis               dev            01b01e89b1f2   3 days ago     5.91GB
bitnami/argo-cd               latest         8c73e989d55c   2 weeks ago    451MB
rancher/k3s-upgrade           v1.29.1-k3s2   92ddfbef6560   2 weeks ago    77.9MB
aegis                         local          4e8467eb9d10   3 weeks ago    5.97GB
ubuntu                        latest         bf3dc08bfed0   6 weeks ago    76.2MB
docker-slim-empty-image       latest         42790182bcac   7 weeks ago     0B
httpd                         2.4            fa0099f1c09d   2 months ago    148MB
cgr.dev/chainguard/postgres   latest         d788f19fbeb7   3 months ago    105MB
neo4j                         4.4            dd60f1e20710   3 months ago    497MB
cgr.dev/chainguard/kubectl    latest         2bfac86afe3e   3 months ago   50.4MB
specterops/bloodhound         latest         c8091c2cc951   3 months ago   93.4MB
debian                        latest         52f537fe0336   3 months ago    116MB
quay.io/derailed/k9s          latest         8620d34236ff   5 months ago    152MB
pandoc/extra                  latest         e8aaded5ca33   14 months ago   915MB
lazyteam/lazydocker           latest         6518a6686572   2 years ago    55.7MB
postgres                      13.2           82b8b88e26bc   3 years ago     314MB
plass/mdtopdf                 latest         3268bc5faa8a   3 years ago    2.01GB
```

### Example 2

```
 ~  $ docker image rm httpd:2.4
Untagged: httpd:2.4
Untagged: httpd@sha256:73b2e9e2861bcfe682b9a67d83433b6a6b36176459134aa25ec711058075fd47
Deleted: sha256:fa0099f1c09d7d1dc852123c9456a23436df95715812df3db8b960ef6609e288

```

### Example 3

```
 ~  $ docker image rm 82b8b88e26bc
Untagged: postgres:13.2
Untagged: postgres@sha256:0eee5caa50478ef50b89062903a5b901eb818dfd577d2be6800a4735af75e53f
Deleted: sha256:82b8b88e26bcfa205a3fd81c9f0a1d84e1a6a8f5f2499f54668c17de94262148
Deleted: sha256:1f82b6b7009661837c5afc0f376951e856419664c28ba3ff90547dcdb222f5a6
Deleted: sha256:f7dc0c3e14a612a19609d59ad59abaffd5aece82b012a4057068ee315b29f7d3
Deleted: sha256:32be5cc3d9f966fb5558fa4cc804010571a78845f0f4c3d462cafc3799eaf308
Deleted: sha256:44b0a3b2c1de0bfca1c2ce99a58e7a253dc8ddd1214be90bdac745fa3a65d1b3
Deleted: sha256:be22136d0529fa512f9bc61bdff9eab156a91a4ce8d431921d2bba050d990354
Deleted: sha256:3c5f695312af6c3f1bace1548b69702a592e6d93e9d813bc2626e66639a8f109
Deleted: sha256:1ecc4ca56779d060ab771a0a97f95c55222c54e76315c7d3508b4cdb07d4b379
Deleted: sha256:c6aa7bd76d2439562106e364ed7afafeb3ef20cf11ccecf07dfb24f0fc5b57fe
Deleted: sha256:6334d51b3f6ca36aa1b9a3f47b11d4c817cc7d2ec57cfb374087ec4480d0cf8c
Deleted: sha256:f8dcd5511126bc0496eea80dfa84d284c439621b855427812b6ed58d0f5442eb
Deleted: sha256:ed6b2836a50984859ad41483f300ce89dd3f3e265a8257aec3cbf99fcfdbb908
Deleted: sha256:afac210c368ff0cd84946322a370af20274d14447a93b1b7818c2a960cb4e401
Deleted: sha256:e276aa5564e0172b85247e18a24ea0ffdeb2d60d718f3b96dcdc67e18a9711b2
Deleted: sha256:02c055ef67f5904019f43a41ea5f099996d8e7633749b6e606c400526b2c4b33

```

### Example 4

```
 ~  $ docker image tag debian:latest debian:demo

 ~  $ docker image ls | grep demo
debian            demo           52f537fe0336   3 months ago    116MB

```

## `docker run`

### Example 1

```
docker run \
-it \
--rm \
-v `pwd`:/root/data \
--net=host \
ubuntu:24.10
```

- `-it` - interactive terminal
- `--rm` - removes container after exit
- `--net=host` - uses host network versus Docker bridge
- `-v`pwd`:/root/data`

### Example 2

```
#prints user id of container which runs as root by default from within the container

 ~  $ docker run -it --rm debian:latest id
uid=0(root) gid=0(root) groups=0(root)
```

## `docker build`

### Example 1

```

~ $ mkdir Docker_Course && cd Docker_Course

Docker_Course  $  vim Dockerfile

FROM ubuntu

RUN apt-get update && apt-get install curl wget git

CMD curl https://fr3d.dev

# save and close the file

# build the image

Docker_Course  $  docker build -t demo:local .

 Docker_Course  $ d run --rm demo:local > index.html
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 10259  100 10259    0     0  84768      0 --:--:-- --:--:-- --:--:-- 85491

 Docker_Course  $ firefox index.html
# the html file will look crazy but this is a rough example of building and running a container

```

## `docker ps`

```bash

 ~  $ docker ps
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES

 ~  $ docker ps -la
CONTAINER ID   IMAGE           COMMAND      CREATED       STATUS    PORTS     NAMES
d069cae603e6   ubuntu:latest   "-it --rm"   5 weeks ago   Created             elegant_mclean

```

## `docker network`

```bash
~  $ docker network ls
NETWORK ID     NAME      DRIVER    SCOPE
3736d73e9fbd   bridge    bridge    local
5c6cc76e16e9   host      host      local
d45ba4357b84   none      null      local

 ~  $ docker network create mynet
 ea2958a08fb81f6bb6a8fa58c611d23b697b3d7896b66d021f115d87a6e23d22 - SHA256 SUM
 ~  $ docker network inspect mynet --format "{{json .Options}}"

{}

 ~  $ docker network ls
 NETWORK ID     NAME      DRIVER    SCOPE
3736d73e9fbd   bridge    bridge    local
5c6cc76e16e9   host      host      local
ea2958a08fb8   mynet     bridge    local
d45ba4357b84   none      null      local\

 ~  $ docker network ls | grep mynet
ea2958a08fb8   mynet     bridge    local

```

# Section 5: Docker Demo

Ref: [DevOps Demo #5: Nginx & SSL/TLS with Docker (Updated)](https://fr3d.dev/Nginx-TLS/)

Have folks reference Demo as we move along to verify instructions/quality

Take Home: [DevOps Demo #2: Docker & React Web App](https://fr3d.dev/dev-box/)

# Section 6: Conclusion

This is a basic overview of Docker and relevant use cases

Topics for further practice:

- Building Docker images from tarbells and exporting containers/images to tarbells
- Docker compose
-

