#!/bin/sh

# request GCR to check if kibana image already exist
gcloud container images --format=json list-tags gcr.io/strapdata-gcp-partnership/kibana-oss > /tmp/kibana.json
IMG_HASH=`cat /tmp/test.json | jq .[]?.digest | head -1`

if [ "x" == $IMG_HASH"x" ]
then
  echo "Kibana OSS image missing from the strapdata registry, pull it from elastic registry and push it"
  docker pull  "docker.elastic.co/kibana/kibana-oss:6.2.3"
  docker tag docker.elastic.co/kibana/kibana-oss:6.2.3 gcr.io/strapdata-gcp-partnership/kibana-oss:6.2.3
  docker push gcr.io/strapdata-gcp-partnership/kibana-oss:6.2.3
fi