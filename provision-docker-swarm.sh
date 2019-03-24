#!/bin/bash
set -eux

ip=$1
first_node_ip=$2

# if this is the first node, init the swarm, otherwise, join it.
if [ "$ip" == "$first_node_ip" ]; then
    # remove previous join tokens (in case they exist).
    rm -f /vagrant/shared/docker-swarm-join-token-*

    # init the swarm.
    docker swarm init \
        --data-path-addr $ip \
        --listen-addr "$ip:2377" \
        --advertise-addr "$ip:2377" # or 'eth1:2377'

    # save the swarm join tokens into the shared folder.
    mkdir -p /vagrant/shared
    docker swarm join-token manager -q >/vagrant/shared/docker-swarm-join-token-manager.txt
    docker swarm join-token worker -q >/vagrant/shared/docker-swarm-join-token-worker.txt
else
    # join the swarm as a manager.
    docker swarm join \
        --token $(cat /vagrant/shared/docker-swarm-join-token-manager.txt) \
        --data-path-addr $ip \
        --listen-addr "$ip:2377" \
        --advertise-addr "$ip:2377" \
        "$first_node_ip:2377"
fi

# kick the tires.
docker version
docker info
docker network ls
ip link
bridge link
docker run --rm alpine cat /etc/resolv.conf
