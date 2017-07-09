#!/bin/bash
set -eux

# launch the service.
docker service create \
    --constraint 'node.role == manager' \
    --constraint 'node.labels.registry == true' \
    --publish 9000:9000 \
    --mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
    --name portainer \
    portainer/portainer \
        -H unix:///var/run/docker.sock

# dump the version.
container_name="portainer.1.$(
    docker service ps \
        --no-trunc \
        -q \
        -f desired-state=running \
        -f name=portainer.1 \
        portainer \
        | head -1)"
docker exec $container_name /portainer --version
