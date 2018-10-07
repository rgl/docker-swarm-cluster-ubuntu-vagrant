#!/bin/bash
set -eux
docker service create \
    --with-registry-auth \
    --constraint 'engine.labels.os == linux' \
    --placement-pref 'spread=engine.labels.os' \
    --secret example-secret-a \
    --secret example-secret-b \
    --config source=example-config-a.toml,target=/run/configs/example-config-a.toml \
    --config source=example-config-b.toml,target=/run/configs/example-config-b.toml \
    -e EXAMPLE_SECRET=/run/secrets/example-secret-a \
    --replicas 3 \
    --publish published=8000,target=8000 \
    --name go-info \
    registry.example.com:5000/go-info:1.0.0

