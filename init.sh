#!/bin/sh

docker build -t centos:lamp .
docker run -d -t -p 10080:80 -p 10022:22 -p 12812:2812 centos:lamp
