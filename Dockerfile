# Use specific version tags for reproducible builds
FROM alpine:3.22 AS builder

RUN apk update && \
  apk add --no-cache \
  --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community hugo \
  ca-certificates && \
  rm -rf /var/cache/apk/*

WORKDIR /tmp/app

COPY app .

RUN hugo --minify --gc

FROM nginx:1.29-alpine-slim

RUN apk update && \
  apk add --no-cache \
  ca-certificates \
  tzdata && \
  rm -rf /var/cache/apk/* && \
  rm -rf /usr/share/nginx/html/*

COPY --chown=root:root ./nginx/nginx.conf /etc/nginx/nginx.conf

COPY --chown=root:root ./nginx/blog /etc/nginx/conf.d/default.conf

RUN chmod 644 /etc/nginx/nginx.conf /etc/nginx/conf.d/default.conf

RUN addgroup -g 1001 -S app && \
  adduser -S -D -H -u 1001 -h /usr/share/nginx/html -s /sbin/nologin -G app -g app app

WORKDIR /usr/share/nginx/html

COPY --from=builder --chown=app:app /tmp/app/public .

RUN find /usr/share/nginx/html -type f -exec chmod 644 {} \; && \
  find /usr/share/nginx/html -type d -exec chmod 755 {} \;

RUN chown -R app:app /var/cache/nginx && \
  chown -R app:app /var/log/nginx && \
  chown -R app:app /usr/share/nginx/html

EXPOSE 8080/tcp

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/ || exit 1

USER app

CMD ["nginx", "-g", "daemon off;"]
