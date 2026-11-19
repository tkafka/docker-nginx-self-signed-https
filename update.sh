#!/usr/bin/env bash
set -Eeuo pipefail

log=$(mktemp "${TMPDIR:-/tmp}/nginx-image-update.log.XXXXXX")
printf 'Release log: %s\n' "$log"
exec 3>&1
exec >>"$log" 2>&1

work=
container=
candidate=
cleanup() {
    if [[ -n "$container" ]]; then docker rm -f "$container" >/dev/null 2>&1 || true; fi
    if [[ -n "$candidate" ]]; then docker image rm "$candidate" >/dev/null 2>&1 || true; fi
    if [[ -n "$work" ]]; then rm -rf "$work"; fi
}
trap cleanup EXIT
trap 'printf "Release failed at line %s (exit %s). See %s\n" "$LINENO" "$?" "$log" >&2; exit 1' ERR

cd "$(dirname "${BASH_SOURCE[0]}")"
branch=$(git symbolic-ref --short HEAD)
if [[ -n "$(git status --porcelain --untracked-files=no)" ]]; then
    echo 'Commit or stash tracked changes before releasing.' >&2
    exit 1
fi
git fetch --tags origin "$branch"
if [[ "$(git rev-parse HEAD)" != "$(git rev-parse FETCH_HEAD)" ]]; then
    echo 'Synchronize the current branch with origin before releasing.' >&2
    exit 1
fi

work=$(mktemp -d "${TMPDIR:-/tmp}/nginx-image-build.XXXXXX")
mkdir "$work/source"
git archive HEAD | tar -x -C "$work/source"

image=tomaskafka/docker-nginx-self-signed-https
nginx_version=$(git ls-remote --tags --refs https://github.com/nginx/nginx.git 'release-*' |
    sed -nE 's|.*refs/tags/release-([0-9]+\.[0-9]+\.[0-9]+)$|\1|p' | sort -V | tail -1)
previous=$(git tag --list 'v2.*' | sed -nE 's/^v(2\.[0-9]+\.[0-9]+)$/\1/p' | sort -V | tail -1)
[[ -n "$nginx_version" && -n "$previous" ]]
release="${previous%.*}.$(( ${previous##*.} + 1 ))"
tag="v$release"
printf 'nginx %s, sidecar release %s\n' "$nginx_version" "$release"

python3 - "$work/source/Dockerfile" "$nginx_version" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
updated, count = re.subn(r'^FROM nginx:[0-9.]+-alpine$', f'FROM nginx:{sys.argv[2]}-alpine', path.read_text(), flags=re.M)
if count != 1:
    raise SystemExit('Expected one pinned nginx Alpine base')
path.write_text(updated)
PY

if docker buildx imagetools inspect "$image:$release" >"$work/existing-image" 2>&1; then
    echo "Docker Hub already has $image:$release. Reconcile the release tag before retrying." >&2
    exit 1
fi
if ! grep -qiE 'not found|manifest unknown|name unknown' "$work/existing-image"; then
    cat "$work/existing-image" >&2
    exit 1
fi
candidate="$image:check-$release-$"
docker buildx build --pull --platform linux/amd64 --load --build-arg "VERSION=$release" -t "$candidate" "$work/source"
docker run --rm --platform linux/amd64 --entrypoint nginx "$candidate" -v 2>&1 | grep -F "nginx/$nginx_version"
openssl req -x509 -nodes -newkey rsa:2048 -subj /CN=localhost -days 1 \
    -keyout "$work/cert.key" -out "$work/cert.crt"
docker run --rm --platform linux/amd64 \
    -v "$work/cert.crt:/etc/nginx/cert.crt:ro" \
    -v "$work/cert.key:/etc/nginx/cert.key:ro" "$candidate" nginx -t

docker buildx build --pull --platform linux/amd64,linux/arm64 --push \
    --build-arg "VERSION=$release" -t "$image:$release" -t "$image:2" -t "$image:latest" "$work/source"
docker buildx imagetools inspect "$image:$release"

cp "$work/source/Dockerfile" Dockerfile
git add -- Dockerfile
git commit --allow-empty -m "Release $release with refreshed upstream dependencies"
git tag -a "$tag" -m "Release $release"
git push --atomic origin "HEAD:refs/heads/$branch" "refs/tags/$tag"
printf 'Released %s:%s. Log: %s\n' "$image" "$release" "$log"
printf 'Released %s:%s. Log: %s\n' "$image" "$release" "$log" >&3
