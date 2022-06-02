#!/bin/sh

docker compose -f docker-compose.yml -f docker-compose.development.yml up \
    --build --exit-code-from ideals-development