#!/bin/bash
set -eux

registry_ip=$1

cat >>/etc/hosts <<EOF
$1 registry.example.com
EOF
