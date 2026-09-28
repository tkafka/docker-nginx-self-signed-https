# Nginx Proxy with bring-your-own certificate

This is a small docker image which can be used as a reverse proxy in front of
your locally running service. It acts as an HTTPS-terminating proxy: it accepts
HTTPS using a certificate you provide and forwards plain HTTP to your app.

Features: HTTP → HTTPS redirect, HTTP/2, WebSocket pass-through, modern TLS
(1.2/1.3 only), unbuffered streaming of large uploads/downloads, and an
optional path-routed secondary upstream.

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

### Optional secondary upstream

Applications can route one path prefix to a second container while keeping all
other requests on `REMOTE_URL`. Both ordinary HTTP and WebSocket connections
are supported:

```bash
-e SECONDARY_PATH_PREFIX=/notification \
-e SECONDARY_REMOTE_URL=http://notification-server:8083/
```

When these variables are omitted, the secondary route is disabled and all
application traffic continues to use `REMOTE_URL`.

As with standard Nginx `proxy_pass` semantics, a trailing slash on the secondary
URL strips the matched prefix (`/notification/ping` becomes `/ping` upstream).

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

## Versioning

The image follows [semantic versioning](https://semver.org/) and is published
under three kinds of tags, mirroring the convention used by the official nginx
image (`1.31.2` / `1.31` / `1`):

| Tag             | Example  | Moves?                          | Use when…                                  |
| --------------- | -------- | ------------------------------- | ------------------------------------------ |
| Exact version   | `2.0.0`  | never                           | fully reproducible, frozen deploy          |
| Major (rolling) | `2`      | re-pointed on every 2.x release | automatic 2.x updates, never a 3.x break   |
| `latest`        | `latest` | re-pointed on every release     | local testing only — avoid in deployments  |

**Recommended for deployments:** pin the rolling major tag, e.g.
`image: tomaskafka/docker-nginx-self-signed-https:2`. You get patches and
minor updates on `docker compose pull` / redeploy, but a major bump (`3.x`) —
which may break the container contract — is opt-in.

Bump the **major** version for breaking changes (e.g. the 1.x → 2.x change that
removed the `run.sh` entrypoint; any deployment overriding `command: "/run.sh"`
must drop that override). Bump **minor**/**patch** for compatible changes.

The chosen version is stamped into the image as the
`org.opencontainers.image.version` OCI label (via the `VERSION` build arg) and
tagged in git as `vX.Y.Z`.

### Cut a release

```bash
VERSION=2.0.0                 # bump per semver
MAJOR=${VERSION%%.*}          # -> 2

# 1. tag the code
git tag -a v$VERSION -m "v$VERSION" && git push --tags

# 2. build + push all three tags in one go
docker buildx build --platform linux/amd64,linux/arm64 --push \
  --build-arg VERSION=$VERSION \
  -t tomaskafka/docker-nginx-self-signed-https:$VERSION \
  -t tomaskafka/docker-nginx-self-signed-https:$MAJOR \
  -t tomaskafka/docker-nginx-self-signed-https:latest .
```
