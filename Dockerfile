ARG NGINX_VERSION=1.16.1
ARG NGINX_RTMP_VERSION=1.2.1
ARG FFMPEG_VERSION=4.2.2


##############################
# Build the NGINX-build image.
FROM alfg/nginx-rtmp

RUN apk add --update nodejs npm
RUN mkdir -p /root/app
COPY record-to-replay /root/app

ADD crontab.save /root/crontab.save
RUN crontab /root/crontab.save

ADD nginx/nginx.conf /etc/nginx/nginx.conf.template
RUN mkdir -p /opt/data
ADD nginx/static /www/static

EXPOSE 1935
EXPOSE 80
RUN pwd
CMD envsubst "$(env | sed -e 's/=.*//' -e 's/^/\$/g')" < \
  /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf && \
  mkdir -p /opt/data/hls && chmod 755 /opt/data/hls && \
  nginx
