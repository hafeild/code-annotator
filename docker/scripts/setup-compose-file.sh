#!/bin/bash

## Creates/overwrites the file docker/Compose.prod.yml, filled with the host 
## port specified in config/application.yaml (PROD_HOST_PORT).

hostPort=$(grep PROD_HOST_PORT: config/application.yml | perl -pe 's/(^.*: )|\s//g')

cat > docker/Compose.prod.yml << EOF
services:
  db:
    image: postgres
    volumes:
      - ../prod-db:/var/lib/postgresql/data
    environment:
      POSTGRES_PASSWORD: password
  web:
    build: 
      context: ../
      dockerfile: docker/Docker.prod
    command: ash docker/scripts/prod-start.sh
    volumes:
      - ..:/usr/src/app
    ports:
      - "$hostPort:5000"
    depends_on:
      - db
EOF