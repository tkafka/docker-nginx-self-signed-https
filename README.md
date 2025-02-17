# Nginx Proxy with bring-your-own certificate

This is a small docker image which can be used as a reverse proxy before your
local running service. It acts as a HTTP terminating proxy.

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
  tkafka/nginx-self-signed-https:latest
```

Note: You can pick your own values for http and https port. 

## Build and push on m1 - this is the way

See [howto](https://blog.jaimyn.dev/how-to-build-multi-architecture-docker-images-on-an-m1-mac/)

Init once:
`docker buildx create --use`

Build and push:
`docker buildx build --platform linux/amd64,linux/arm64 --push -t tomaskafka/docker-nginx-self-signed-https:latest .`