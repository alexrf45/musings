#!/bin/bash

#docker stop blog

#git submodule update --init

docker image rm blog:test

docker build -f ./dockerfile -t blog:test . --no-cache

docker run --name blog --rm -p 80:8080 -it blog:test
