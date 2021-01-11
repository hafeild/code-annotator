#!/bin/sh

docker-compose -f docker/Compose.prod.yml build
docker-compose -f docker/Compose.prod.yml up