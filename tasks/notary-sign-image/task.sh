#!/bin/bash
set -e

source /opt/resource/common.sh

export DOCKER_CONTENT_TRUST_SERVER="https://$HARBOR_URL:4443"
export DOCKER_CONTENT_TRUST_ROOT_PASSPHRASE="u7pEQcGoebUHm6LHe6"
export DOCKER_CONTENT_TRUST_REPOSITORY_PASSPHRASE="l7pEQcTKJjUHm6Lpe4"

function fn_decode {
  echo $1 | base64 -d
}


function fn_notary_keys {
  mkdir -p /root/.docker/trust/private
  echo $NOTARY_KEY_1 | base64 -d > /root/.docker/trust/private/$NOTARY_FILE_1
  echo $NOTARY_KEY_2 | base64 -d > /root/.docker/trust/private/$NOTARY_FILE_2
}

mkdir -p /etc/docker/certs.d/$HARBOR_URL
fn_decode $HARBOR_CA_CERT > "/etc/docker/certs.d/$HARBOR_URL/ca.cert"
fn_decode $HARBOR_CA_KEY > "/etc/docker/certs.d/$HARBOR_URL/ca.key"
echo "{\"insecure-registries\" : [\"$HARBOR_URL\"]}" > /etc/docker/daemon.json
mkdir -p "$HOME/.docker/tls/$HARBOR_URL:4443"
fn_decode $HARBOR_CA_CERT > "$HOME/.docker/tls/$HARBOR_URL:4443/ca.crt"
fn_decode $HARBOR_CA_CERT > "$HOME/.docker/tls/$HARBOR_URL:4443/ca.cert"
fn_decode $HARBOR_CA_KEY > "$HOME/.docker/tls/$HARBOR_URL:4443/ca.key"

start_docker


docker login $HARBOR_URL -u $HARBOR_USERNAME -p $HARBOR_PASSWORD
docker pull $HARBOR_IMAGE
docker images

export DOCKER_CONTENT_TRUST=1
fn_notary_keys
docker push $HARBOR_IMAGE 2>/dev/null
