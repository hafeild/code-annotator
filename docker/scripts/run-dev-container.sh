#!/bin/sh

#####
# Fires up the development container; use ctrl-c to drop to the command line,
# and then exit to stop and remove the container. The code-annotator repo toot
# on the host is mounted as a volume, so all files (logs, sqlite database, etc.)
# are persistent.
#####

## Grab the development host port from config/application.yml (DEV_HOST_PORT).
hostPort=$(grep DEV_HOST_PORT: config/application.yml | perl -pe 's/(^.*: )|\s//g')

docker run -ti --rm -p $hostPort:3000 -v "$PWD:/usr/src/app" code-annotator-dev