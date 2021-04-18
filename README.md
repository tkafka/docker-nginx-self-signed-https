# Nginx Proxy with bring-your-own certificate

This is a small docker image which can be used as a reverse proxy before your
local running service. It acts as a HTTP terminating proxy.

## Usage

```bash
docker run -d --name app-roxy --net host \
  -e REMOTE_URL=http://127.0.0.1:8080 \
  -e HTTP_PORT=80 \
  -e HTTPS_PORT=443 \
  --mount type=bind,source=LOCATION_OF_CERT,target=/etc/nginx/cert.crt,readonly \
  --mount type=bind,source=LOCATION_OF_KEY,target=/etc/nginx/cert.key,readonly \
  tkafka/nginx-self-signed-https:latest
```

Note: This is running the container on the host network. It is required that
port 80 and 443 are not used by any other application. Also this does only work
when Docker can be ran natively. This won't work on Mac OS X and Windows.
