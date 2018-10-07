#!/bin/bash
set -eux

# launch the service.
docker service create \
    --constraint 'node.role == manager' \
    --constraint 'node.labels.registry == true' \
    --publish published=9000,target=9000 \
    --mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
    --name portainer \
    portainer/portainer \
        -H unix:///var/run/docker.sock

# get the first expected container name.
container_name="portainer.1.$(
    docker service ps \
        --no-trunc \
        -q \
        -f desired-state=running \
        -f name=portainer.1 \
        portainer \
        | head -1)"

# wait for the container to be running.
bash -c "while [ -z \"\$(docker ps -q -f 'name=$container_name' -f status=running)\" ]; do sleep 1; done"

# dump the portainer version.
docker exec $container_name /portainer --version
