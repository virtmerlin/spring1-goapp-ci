#!/bin/bash
set -e


# Install clairctl
sed -i -e 's/us.archive.ubuntu.com/archive.ubuntu.com/g' /etc/apt/sources.list
apt-get -y update
apt-get -y install curl

curl -L https://raw.githubusercontent.com/jgsqware/clairctl/master/install.sh | sh

export CLAIR_CONFIG=$HOME/clairctl.yml
echo "clair:" > $CLAIR_CONFIG
echo "  healthPort: $CLAIR_HEALTH_PORT" >> $CLAIR_CONFIG
echo "  uri: $CLAIR_URL" >> $CLAIR_CONFIG
echo "  report:" >> $CLAIR_CONFIG
echo "    format: html" >> $CLAIR_CONFIG
echo "docker:" >> $CLAIR_CONFIG
echo "  insecure-registries:" >> $CLAIR_CONFIG
echo "  - \"$CLAIR_INSECURE_REGISTRY\"" >> $CLAIR_CONFIG

clairctl --config $CLAIR_CONFIG health

# Scan the image

export HIGH=$(clairctl --config $CLAIR_CONFIG --log-level Debug analyze $CLAIR_IMAGE | tee /dev/stderr | grep High | awk '{print$2}')


if [[ $HIGH -lt 1 ]]; then
  echo "+++Image $CLAIR_IMAGE has passed scan threshold+++"
else
  echo "---Image $CLAIR_IMAGE has failed scan threshold+++"
  exit 1
fi
