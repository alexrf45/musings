FROM alpine:latest AS builder

RUN apk update \
 && apk add --no-cache hugo

WORKDIR /tmp/app

COPY app .

RUN hugo --minify

FROM nginx:alpine-slim

COPY ./nginx/nginx.conf /etc/nginx/nginx.conf

COPY ./nginx/default /etc/nginx/sites-enabled/default

WORKDIR /usr/share/nginx/html

COPY --from=builder /tmp/app/public .

EXPOSE 80/tcp

CMD ["nginx", "-g", "daemon off;"]
