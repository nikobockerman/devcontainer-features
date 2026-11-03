#!/bin/bash

# Checks that a feature's data survives a container rebuild, which the
# `devcontainer features test` harness cannot do: it gets one container per
# test and the test scripts run inside it.
#
# Uses the fixture in test/<feature>/rebuild/: brings the dev container up,
# runs before.sh in it, recreates the container the way "Rebuild Container"
# does, and runs after.sh in the new container. Both scripts get a per-run
# REBUILD_TOKEN so that a volume left over from an earlier run cannot pass
# the test.
#
# Usage: scripts/test-rebuild.sh <feature>

set -euo pipefail

feature=${1:?usage: $0 <feature>}
repo=$(cd "$(dirname "$0")/.." && pwd)
fixture=$repo/test/$feature/rebuild
[ -d "$fixture" ] || { echo "No rebuild fixture at $fixture" >&2; exit 1; }

ws=$(mktemp -d)
containers=()
volume=

cleanup() {
    # ${a[@]+...} expands to nothing for an empty array; plain "${a[@]}" is an
    # unbound-variable error under set -u in bash < 4.4 (macOS /bin/bash).
    for id in ${containers[@]+"${containers[@]}"}; do
        docker rm -f "$id" >/dev/null 2>&1 || true
    done
    if [ -n "$volume" ]; then
        docker volume rm "$volume" >/dev/null 2>&1 || true
    fi
    rm -rf "$ws"
}
trap cleanup EXIT

mkdir "$ws/.devcontainer"
cp -R "$fixture"/. "$ws/.devcontainer/"
cp -R "$repo/src/$feature" "$ws/.devcontainer/$feature"
cp "$repo/scripts/rebuild-lib.sh" "$ws/.devcontainer/"

token=$(date +%s)-$RANDOM

# Sets container_id from `devcontainer up` and records it for cleanup. Not
# called via $(...): that would run it in a subshell and lose the record.
up() {
    container_id=$(devcontainer up --workspace-folder "$ws" "$@" | jq -r .containerId)
    containers+=("$container_id")
}

feature_volume() {
    docker inspect "$1" \
        --format '{{range .Mounts}}{{if eq .Type "volume"}}{{println .Name}}{{end}}{{end}}' |
        grep "^$feature-"
}

run_in_container() {
    devcontainer exec --workspace-folder "$ws" --remote-env "REBUILD_TOKEN=$token" \
        bash ".devcontainer/$1"
}

echo "::group::Create container and write data"
up
first=$container_id
volume=$(feature_volume "$first")
run_in_container before.sh
echo "::endgroup::"

echo "::group::Rebuild container and check data"
up --remove-existing-container
second=$container_id
run_in_container after.sh
echo "::endgroup::"

# shellcheck source=SCRIPTDIR/rebuild-lib.sh
source "$repo/scripts/rebuild-lib.sh"
check "rebuild created a new container" test "$first" != "$second"
check "new container uses the same volume" test "$(feature_volume "$second")" = "$volume"
report_results
