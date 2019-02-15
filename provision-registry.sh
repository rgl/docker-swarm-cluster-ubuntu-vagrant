#!/bin/bash
set -eux

# name of the registry image to use.
registry_image='registry:2.7.1'

# generate the registry certificate and the corresponding swarm secrets.
bash /vagrant/provision-certificate.sh registry.example.com
docker secret create registry.example.com-crt.pem /vagrant/shared/*/registry.example.com-crt.pem
docker secret create registry.example.com-key.pem /vagrant/shared/*/registry.example.com-key.pem

# set the registry http secret.
echo -n 'http secret' | docker secret create registry_http_secret -

# add a label to the current node, as this is where the registry will run (due to
# the usage of a local storage directory).
docker node update --label-add registry=true $(hostname)
#docker node inspect $(hostname)

# create a registry user.
mkdir -p /vagrant/shared/registry/auth
docker run \
    --rm \
    --entrypoint htpasswd \
    $registry_image -Bbn vagrant vagrant >/vagrant/shared/registry/auth/htpasswd

# launch the registry.
# see https://docs.docker.com/registry/deploying/
mkdir -p /vagrant/shared/registry/data
docker service create \
    --constraint 'node.labels.registry == true' \
    --publish published=5000,target=5000 \
    --secret registry_http_secret \
    -e REGISTRY_HTTP_SECRET=/run/secrets/registry_http_secret \
    --secret registry.example.com-crt.pem \
    --secret registry.example.com-key.pem \
    --mount type=bind,src=/vagrant/shared/registry/data,dst=/var/lib/registry \
    -e REGISTRY_HTTP_ADDR=0.0.0.0:5000 \
    -e REGISTRY_HTTP_TLS_CERTIFICATE=/run/secrets/registry.example.com-crt.pem \
    -e REGISTRY_HTTP_TLS_KEY=/run/secrets/registry.example.com-key.pem \
    --mount type=bind,src=/vagrant/shared/registry/auth,dst=/auth,readonly \
    -e REGISTRY_AUTH=htpasswd \
    -e 'REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm' \
    -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \
    --name registry \
    $registry_image

# wait for the registry to be available.
bash -c 'while ! wget -q --spider --user vagrant --password vagrant https://registry.example.com:5000/v2/; do sleep 1; done;'

# login into the registry.
docker login registry.example.com:5000 -u vagrant -p vagrant

# list images.
wget -qO- --user vagrant --password vagrant \
    https://registry.example.com:5000/v2/_catalog

# dump the registry configuration.
container_name="registry.1.$(
    docker service ps \
        --no-trunc \
        -q \
        -f desired-state=running \
        -f name=registry.1 \
        registry \
        | head -1)"
docker exec $container_name registry --version
docker exec $container_name env
docker exec $container_name cat /etc/docker/registry/config.yml
