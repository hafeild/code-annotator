#!/bin/sh

#####
# Builds the containers for production (db and web) and launches them.
#####


# Check if the compose file has been generated; if not, generate it.
if [ ! -f "docker/Compose.prod.yml" ]; then 
    docker/scripts/setup-compose-file.sh
fi

docker-compose -f docker/Compose.prod.yml up -V --force-recreate --build
