#!/bin/bash
set -eux

portainer_agent_image='portainer/agent:1.2.1'
portainer_image='portainer/portainer:1.20.2'

# deploy the portainer stack.
# NB you can destroy it with:
#       docker stack rm portainer
#    NB docker stack rm is asyncronous, so the remove is done in background
#       and will be done after a while.
#    BUT docker stack rm does not automatically remove the volumes, for that,
#        you need to remove all containers that use that volume, which are
#        the portainer ones:
#           docker ps -q -f name=portainer_portainer -f status=exited --no-trunc | xargs docker rm
#        and finally remove the volume:
#           docker volume rm portainer_portainer_data
#    see https://github.com/moby/moby/issues/29158
# see https://portainer.readthedocs.io/en/stable/deployment.html#inside-a-swarm-cluster
# see https://docs.docker.com/compose/compose-file/
docker stack deploy --compose-file - portainer <<EOF
version: '3.2'
services:
    agent:
        image: $portainer_agent_image
        environment:
            # REQUIRED: Should be equal to the service name prefixed by "tasks." when
            # deployed inside an overlay network
            AGENT_CLUSTER_ADDR: tasks.agent
            # AGENT_PORT: 9001
            # LOG_LEVEL: debug
        volumes:
            - /var/run/docker.sock:/var/run/docker.sock
            - /var/lib/docker/volumes:/var/lib/docker/volumes
        networks:
            - agent
        deploy:
            mode: global
            placement:
                constraints:
                    - node.platform.os == linux
    portainer:
        image: $portainer_image
        command: -H tcp://tasks.agent:9001 --tlsskipverify --no-auth
        ports:
            - '9000:9000'
        volumes:
            - portainer_data:/data
        networks:
            - agent
        deploy:
            mode: replicated
            replicas: 1
            placement:
                constraints:
                    - node.role == manager
                    - node.labels.registry == true
networks:
    agent:
        driver: overlay
        attachable: true
        internal: true
volumes:
    portainer_data:
EOF

# wait for a portainer container to be up and dump its version.
# NB we need to loop because the first container will fail to execute
#    because the agent has not yet started.
set +x
echo 'Waiting for Portainer to be up...'
while true; do
    container_name_suffix="$(
        docker service ps \
            --no-trunc \
            -q \
            -f desired-state=running \
            -f name=portainer_portainer.1 \
            portainer_portainer \
            | head -1)"
    if [ -z "$container_name_suffix" ]; then
        sleep 1
        continue
    fi

    container_name="portainer_portainer.1.$container_name_suffix"
    if [ -z "$(docker ps -q -f "name=$container_name" -f status=running)" ]; then
        sleep 1
        continue
    fi

    # NB this seems more complicated that needed because, sometimes, docker exec
    #    fails with "unable to upgrade to tcp, received 500" when the container
    #    dies while it tries to exec into it.
    portainer_version="$(docker exec $container_name /portainer --version 2>&1 | grep -E '^[0-9]+\.[0-9]+\.[0-9]+' || true)"
    if [ -z "$portainer_version" ]; then
        sleep 1
        continue
    fi

    echo "Portainer v$portainer_version is up!"
    break
done
set -x
