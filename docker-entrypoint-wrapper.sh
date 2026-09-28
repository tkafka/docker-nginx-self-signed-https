#!/bin/sh
set -eu

# By default the secondary location points at the primary upstream and uses an
# unreachable sentinel prefix, preserving the image's original single-upstream
# behaviour. Applications with a path-routed auxiliary service can override
# both variables (for example Seafile Notification Server).
export SECONDARY_REMOTE_URL="${SECONDARY_REMOTE_URL:-$REMOTE_URL}"

exec /docker-entrypoint.sh "$@"
