#!/bin/sh

docker-compose -f docker/Compose.prod.yml up -V --force-recreate --build
