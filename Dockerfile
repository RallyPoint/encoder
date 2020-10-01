FROM nginx:alpine

ENV NODE_VERSION 14.11.0

# ------------------ FFMPEG ----------------------- #
RUN apk update
RUN apk add ffmpeg
# ------------------------------------------------- #

# ------------------ NODEJS ----------------------- #
RUN apk add --update nodejs nodejs-npm
# ------------------------------------------------- #

# ------------------ MAKE ----------------------- #

WORKDIR /usr/app
COPY . /usr/app
COPY ./nginx.conf /etc/nginx/nginx.conf
EXPOSE 1935

RUN npm i
