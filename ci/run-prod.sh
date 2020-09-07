#!/bin/bash

envsubst "$(env | sed -e 's/=.*//' -e 's/^/\$/g')" < \
  /usr/local/srs/conf/srs.conf.template > /usr/local/srs/conf/srs.conf && \
  mkdir -p /opt/data/hls && chmod 755 /opt/data/hls && \
  ./objs/srs -c conf/srs.conf
