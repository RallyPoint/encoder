FROM registry.cn-hangzhou.aliyuncs.com/ossrs/srs:3

ADD hls.conf /usr/local/srs/conf/srs.conf.template

EXPOSE 1935
EXPOSE 80
RUN pwd
WORKDIR /usr/local/srs

CMD envsubst "$(env | sed -e 's/=.*//' -e 's/^/\$/g')" < \
  /usr/local/srs/conf/srs.conf.template > /usr/local/srs/conf/srs.conf && \
  mkdir -p /opt/data/hls && chmod 755 /opt/data/hls && \
  ./objs/srs -c conf/srs.conf
