#!/bin/sh
#
# When run with no arguments, this script starts the web application stack.
# It also accepts an argument of a rake task, when the stack is already
# running.
#

if [ -z "$1" ]; then
    docker compose \
        -f docker-compose.yml \
        -f docker-compose.development.yml \
        up \
        --build \
        --exit-code-from ideals-development
else
    docker compose \
        -f docker-compose.yml \
        -f docker-compose.development.yml \
        exec \
        ideals-development \
        /bin/bash -c "bin/rails $1"
fi
