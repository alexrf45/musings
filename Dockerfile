# Reference
# https://medium.com/@lorique/howto-multi-stage-docker-builds-with-hugo-78a53565d567

#####################################################################
#                            Build Stage                            #
#####################################################################
# Stage 1
FROM alpine:latest AS builder

RUN apk update \
 && apk add --no-cache hugo

WORKDIR /tmp/app

COPY app .

RUN hugo --minify

#####################################################################
#                            Deploy Stage                           #
#####################################################################

# Stage 2
FROM nginx:alpine-slim

COPY ./nginx/nginx.conf /etc/nginx/nginx.conf

COPY ./nginx/default /etc/nginx/sites-enabled/default

WORKDIR /usr/share/nginx/html

# Copy the generated files to keep image as small as possible.
COPY --from=builder /tmp/app/public .

EXPOSE 80/tcp

CMD ["nginx", "-g", "daemon off;"]
