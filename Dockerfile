# Reference
# https://medium.com/@lorique/howto-multi-stage-docker-builds-with-hugo-78a53565d567

#####################################################################
#                            Build Stage                            #
#####################################################################
# Stage 1
FROM alpine:latest AS build

# Install the Hugo go app.
RUN apk add --update hugo

WORKDIR /opt/app

# Copy Hugo config into the container Workdir.
COPY app .

# Run Hugo in the Workdir to generate HTML.
RUN hugo  --minify

#####################################################################
#                            Deploy Stage                           #
#####################################################################

# Stage 2
FROM cgr.dev/chainguard/nginx:latest

USER nginx
# Set workdir to the NGINX default dir.
WORKDIR /usr/share/nginx/html

# Copy HTML from previous build into the Workdir.
COPY --from=build /opt/app/public .

EXPOSE 8080
