# Pinned to a minor tag: picks up patch/security updates while staying reproducible.
# Alpine keeps the image small; it ships the envsubst template entrypoint too.
FROM nginx:1.31-alpine

# The official image renders every /etc/nginx/templates/*.template file through
# envsubst on startup, writing the result into /etc/nginx/conf.d/. This replaces
# the old custom run.sh + sed approach and keeps nginx's default entrypoint
# (correct signal handling, etc.).
COPY templates/default.conf.template /etc/nginx/templates/default.conf.template
COPY docker-entrypoint-wrapper.sh /usr/local/bin/docker-entrypoint-wrapper.sh

# Image version, stamped in via --build-arg VERSION=x.y.z at build time.
ARG VERSION=dev
LABEL org.opencontainers.image.title="nginx-self-signed-https" \
      org.opencontainers.image.description="HTTPS-terminating nginx reverse proxy with bring-your-own certificate" \
      org.opencontainers.image.source="https://github.com/tkafka/docker-nginx-self-signed-https" \
      org.opencontainers.image.version="${VERSION}"

ENV REMOTE_URL="http://localhost:8080/" \
    SECONDARY_PATH_PREFIX="/__disabled_secondary_route__" \
    HTTP_PORT=80 \
    HTTPS_PORT=443 \
    TIMEOUTS_S=10800 \
    CLIENT_MAX_BODY_SIZE=100G \
    CLIENT_BODY_BUFFER_SIZE=32M

# Resolve SECONDARY_REMOTE_URL from REMOTE_URL at container startup. Dockerfile
# ENV expansion happens at build time, so it cannot follow a runtime REMOTE_URL
# override without this tiny wrapper.
ENTRYPOINT ["/usr/local/bin/docker-entrypoint-wrapper.sh"]
CMD ["nginx", "-g", "daemon off;"]
