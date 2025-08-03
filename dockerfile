# Use specific version tags for reproducible builds
FROM alpine:3.22 AS builder

RUN addgroup -g 1000 -S hugo && \
  adduser -S -D -H -u 1000 -h /tmp/app -s /sbin/nologin -G hugo -g hugo hugo

RUN apk update && \
  apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community hugo \
  ca-certificates && \
  rm -rf /var/cache/apk/*

WORKDIR /tmp/app

RUN chown -R hugo:hugo /tmp/app

USER hugo

COPY --chown=hugo:hugo app .

RUN hugo --minify --gc 

FROM nginx:1.29-alpine-slim

RUN apk update && \
  apk upgrade && \
  apk add --no-cache \
  ca-certificates \
  tzdata && \
  rm -rf /var/cache/apk/* && \
  rm -rf /usr/share/nginx/html/* && \
  mkdir -p /var/cache/nginx/client_temp && \
  mkdir -p /var/cache/nginx/proxy_temp && \
  mkdir -p /var/cache/nginx/fastcgi_temp && \
  mkdir -p /var/cache/nginx/uwsgi_temp && \
  mkdir -p /var/cache/nginx/scgi_temp

COPY --chown=root:root ./nginx/nginx-prod.conf /etc/nginx/nginx.conf
COPY --chown=root:root ./nginx/blog /etc/nginx/conf.d/default.conf

RUN chmod 644 /etc/nginx/nginx.conf /etc/nginx/conf.d/default.conf

RUN addgroup -g 1000 -S nginx-app && \
  adduser -S -D -H -u 1000 -h /var/cache/nginx -s /sbin/nologin -G nginx-app -g nginx-app nginx-app

WORKDIR /usr/share/nginx/html
COPY --from=builder --chown=nginx-app:nginx-app /tmp/app/public .

RUN find /usr/share/nginx/html -type f -exec chmod 644 {} \; && \
  find /usr/share/nginx/html -type d -exec chmod 755 {} \;

RUN chown -R nginx-app:nginx-app /var/cache/nginx && \
  chown -R nginx-app:nginx-app /var/log/nginx && \
  chown -R nginx-app:nginx-app /usr/share/nginx/html

EXPOSE 8080/tcp

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/ || exit 1

USER nginx-app

CMD ["nginx", "-g", "daemon off;"]
