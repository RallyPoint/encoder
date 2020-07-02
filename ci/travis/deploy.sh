#!/bin/bash

echo "--------------"
echo $KUBE_NAMESPACE
echo "--------------"

track="${1-stable}"
name=$(deploy_name "$track")
echo "KUBE_NAMESPACE: $KUBE_NAMESPACE";
helm upgrade --install \
  --wait \
  --set env.HTTP_PORT="$HTTP_PORT" \
  --set env.RTMP_PORT="$RTMP_PORT" \
  --set env.HLS_API="$HLS_API" \
  --namespace="$KUBE_NAMESPACE" \
  "$name" \
  ci/chart/


  function deploy_name() {
    name="$CI_ENVIRONMENT_SLUG"
    track="${1-stable}"

    if [[ "$track" != "stable" ]]; then
      name="$name-$track"
    fi

    echo $name
  }
