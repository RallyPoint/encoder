#!/bin/sh

mv /usr/app/config/prod.json /usr/app/config/prod.json.template

envsubst "$(env | sed -e 's/=.*//' -e 's/^/\$/g')" < \
  /usr/app/config/prod.json.template > /usr/app/config/prod.json && \
  mkdir -p /opt/data/hls && chmod 755 /opt/data/hls && \
  npm run start & nginx -g "daemon off;"

