#!/bin/bash

if [[ $# -lt 2 || $(echo "$@" | grep " -h") ]]; then
    echo "Usage: export-production-database.sh <database name> <database dump file>"
    exit
fi

database=$1
databaseDumpFile=$2

dir=$(mktemp -p . -d data-dump-XXXX);

docker-compose -f docker/Compose.prod.yml run -v "$PWD/$dir":/data -w /data --rm db \
    bash -c "PGPASSWORD=password pg_dump -h db -U postgres -w $database > data.sql"

mv $dir/data.sql $databaseDumpFile
rm -rf $dir