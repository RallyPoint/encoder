#!/bin/sh
man envsubst
envsubst "$(env | sed -e 's/=.*//' -e 's/^/\$/g')" < \
  /usr/local/srs/conf/srs.conf.template > /usr/local/srs/conf/srs.conf && \
  ./objs/srs -c conf/srs.conf
