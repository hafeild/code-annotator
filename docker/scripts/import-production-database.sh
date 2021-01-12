#!/bin/bash

if [[ $# -lt 2 || $(echo "$@" | grep " -h") ]]; then
    echo "Usage: import-production-database.sh <database name> <database dump file>"
    exit
fi

database=$1
databaseDumpFile=$2

docker-compose -f docker/Compose.prod.yml up -V --build --force-recreate -d db

dir=$(mktemp -p . -d data-dump-XXXX);
mv $databaseDumpFile $dir/data.sql

docker-compose -f docker/Compose.prod.yml run --rm -v "$PWD/$dir":/data -w /data db \
    bash -c "export PGPASSWORD=password && \
    createdb -h db -U postgres -w -T template0 $database && \
    psql -h db -U postgres -w $database < data.sql"


mv $dir/data.sql $databaseDumpFile
rm -rf $dir

