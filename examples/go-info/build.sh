#!/bin/bash
set -eux
cd $(dirname $0)

# build the image.
docker build -t go-info:1.0.0 . -f Dockerfile
docker image ls go-info:1.0.0

# push the image to the registry.
docker tag go-info:1.0.0 registry.example.com:5000/go-info:1.0.0
docker push registry.example.com:5000/go-info:1.0.0

# show the repository (image) details directly from the registry.
# see https://docs.docker.com/registry/spec/api/
# see https://docs.docker.com/registry/spec/manifest-v2-2/
wget -qO- --user vagrant --password vagrant \
    https://registry.example.com:5000/v2/go-info/tags/list | jq .
manifest=$(wget -qO- --user vagrant --password vagrant \
    '--header=Accept: application/vnd.docker.distribution.manifest.v2+json' \
    https://registry.example.com:5000/v2/go-info/manifests/1.0.0)
config_digest=$(echo "$manifest" | jq -r .config.digest)
echo "$manifest" | jq .
wget -qO- --user vagrant --password vagrant \
    https://registry.example.com:5000/v2/go-info/blobs/$config_digest | jq .

# remove it from local cache.
docker image remove go-info:1.0.0

# pull it from the registry.
#docker pull registry.example.com:5000/go-info:1.0.0

# create example secrets.
echo -n 'example secret a' | docker secret create example-secret-a -
echo -n 'example secret b' | docker secret create example-secret-b -

# create example configs.
docker config create example-config-a.toml - <<EOF
[config-a]
date = $(date --iso-8601=seconds)
int = 1
EOF
docker config create example-config-b.toml - <<EOF
[config-b]
date = $(date --iso-8601=seconds)
int = 2
EOF
