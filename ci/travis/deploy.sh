#!/bin/bash

echo "--------------"
echo $KUBE_NAMESPACE
echo "--------------"

function deploy_name() {
    name="$CI_ENVIRONMENT_SLUG"
    track="${1-stable}"

    if [[ "$track" != "stable" ]]; then
      name="$name-$track"
    fi

    echo $name
}


track="${1-stable}"
name=$(deploy_name "$track")
echo "KUBE_NAMESPACE: $KUBE_NAMESPACE";
echo "name: $name";


#kubectl create namespace $KUBE_NAMESPACE

RTMP_PORT="1935"
HTTP_PORT="80"
HLS_API="back-back-clusteip.prod.svc.cluster.local"

helm upgrade --install \
  --wait \
  --set env.HTTP_PORT="$HTTP_PORT" \
  --set env.RTMP_PORT="$RTMP_PORT" \
  --set env.HLS_API="$HLS_API" \
  --namespace="$KUBE_NAMESPACE" \
  --set image.tag="$TRAVIS_COMMIT" \
  --create-namespace \
  "$name" \
  ci/chart/


echo "END"
