#!/bin/sh

docker compose rm -f ideals-test
docker compose -f docker-compose.yml -f docker-compose.test.yml up \
    --build --exit-code-from ideals-test

