#!/bin/bash

docker build -t blog:test . --no-cache

docker run --rm -p 8080:8080 -it blog:test
