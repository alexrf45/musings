#!/bin/bash

#docker stop blog

git submodule update --init

docker build -t blog:test . --no-cache

docker run -d --name blog --rm -p 80:80 -it blog:test
