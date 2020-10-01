#!/bin/bash

envsubst "$(env | sed -e 's/=.*//' -e 's/^/\$/g')" < \
  /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf && \
  mkdir -p /opt/data/hls && chmod 755 /opt/data/hls && \
  npm run start & nginx -g "daemon off;"

