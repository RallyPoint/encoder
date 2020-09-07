FROM registry.cn-hangzhou.aliyuncs.com/ossrs/srs:3

WORKDIR /usr/local/srs
RUN yum -y install gettext
RUN pwd
ADD hls.conf /usr/local/srs/conf/srs.conf.template

EXPOSE 1935
EXPOSE 80
CMD envsubst "$(env | sed -e 's/=.*//' -e 's/^/\$/g')" < \
  /usr/local/srs/conf/srs.conf.template > /usr/local/srs/conf/srs.conf && \
  mkdir -p /opt/data/hls && chmod 755 /opt/data/hls && \
  ./objs/srs -c conf/srs.conf
