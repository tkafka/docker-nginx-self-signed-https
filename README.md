# Nginx Proxy with bring-your-own certificate

This is a small docker image which can be used as a reverse proxy in front of
your locally running service. It acts as an HTTPS-terminating proxy: it accepts
HTTPS using a certificate you provide and forwards plain HTTP to your app.

Features: HTTP → HTTPS redirect, HTTP/2, WebSocket pass-through, modern TLS
(1.2/1.3 only), and unbuffered streaming of large uploads/downloads.

## Usage

```bash
docker run -d --name app-proxy --net host \
  -e REMOTE_URL=http://127.0.0.1:8080 \
  -e HTTP_PORT=80 \
  -e HTTPS_PORT=443 \
  -e TIMEOUTS_S=10800 \
  -e CLIENT_MAX_BODY_SIZE=100G \
  -e CLIENT_BODY_BUFFER_SIZE=32M \
  --mount type=bind,source=LOCATION_OF_CERT,target=/etc/nginx/cert.crt,readonly \
  --mount type=bind,source=LOCATION_OF_KEY,target=/etc/nginx/cert.key,readonly \
  tomaskafka/docker-nginx-self-signed-https:latest
```

Note: You can pick your own values for the HTTP and HTTPS ports. All the values
above are defaults baked into the image, so you only need to override the ones
you want to change.

## How it works

The nginx config lives in [`templates/default.conf.template`](templates/default.conf.template).
On container start, the official nginx image renders it through `envsubst`,
substituting the `${...}` environment variables and writing the result to
`/etc/nginx/conf.d/default.conf`. (nginx runtime variables like `$host` are left
untouched.)

## Build and push (multi-arch, e.g. on Apple Silicon)

See [howto](https://blog.jaimyn.dev/how-to-build-multi-architecture-docker-images-on-an-m1-mac/).

Init once:

```bash
docker buildx create --use
```

Build and push:

```bash
docker buildx build --platform linux/amd64,linux/arm64 --push \
  -t tomaskafka/docker-nginx-self-signed-https:latest .
```
