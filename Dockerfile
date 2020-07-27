ARG NGINX_VERSION=1.16.1
ARG NGINX_RTMP_VERSION=1.2.1
ARG FFMPEG_VERSION=4.2.2


##############################
# Build the NGINX-build image.
FROM alfg/nginx-rtmp


ADD nginx.conf /etc/nginx/nginx.conf.template
RUN mkdir -p /opt/data
ADD static /www/static

EXPOSE 1935
EXPOSE 80
RUN pwd
CMD envsubst "$(env | sed -e 's/=.*//' -e 's/^/\$/g')" < \
  /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf && \
  mkdir -p /opt/data/hls && chmod 755 /opt/data/hls && \
  nginx
