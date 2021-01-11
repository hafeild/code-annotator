#!/bin/sh

docker run -ti --rm -p 3000:3000 -v "$PWD:/usr/src/app" code-annotator-dev