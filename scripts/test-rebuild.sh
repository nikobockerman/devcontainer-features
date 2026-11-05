#!/bin/bash

# Checks that a feature's data survives a container rebuild, which the
# `devcontainer features test` harness cannot do: it gets one container per
# test and the test scripts run inside it.
#
# Uses the fixture in test/<feature>/<fixture>/ (rebuild/ by default): brings
# the dev container up, runs before.sh in it, recreates the container with
# `devcontainer up --remove-existing-container` while keeping its volumes
# (what "Rebuild Container" does in VS Code and other dev container tools),
# and runs after.sh in the new container. Both scripts get a per-run
# REBUILD_TOKEN so that a volume left over from an earlier run cannot pass
# the test.
#
# If the fixture has a before.devcontainer.json, the first container is
# created from it instead, for example to start from an earlier published
# version of the feature. It is copied over devcontainer.json rather than
# passed with --config, because the CLI derives the volume name from the
# config file's path and the rebuilt container must get the same volume.
#
# Usage: scripts/test-rebuild.sh <feature> [fixture]

set -euo pipefail

feature=${1:?usage: $0 <feature> [fixture]}
repo=$(cd "$(dirname "$0")/.." && pwd)
fixture=$repo/test/$feature/${2:-rebuild}
if [ ! -d "$fixture" ]; then
    echo "No rebuild fixture at $fixture" >&2
    exit 1
fi

# Physical path, so that it matches the label the CLI puts on the container
# even where the temp dir is behind a symlink (/var -> /private/var on macOS).
ws=$(cd "$(mktemp -d)" && pwd -P)
# The CLI names the images it builds after the workspace folder in
# lowercase: vsc-<folder>-<hash>, with -features and, where it changes the
# user's UID to match the host user, -uid images on top.
images_ref="vsc-$(basename "$ws" | tr '[:upper:]' '[:lower:]')-*"
token=$(date +%s)-$RANDOM
# Filled in as the test runs, for cleanup.
images=
volume=

# Prints the ids of the containers the CLI has created for the workspace,
# including one left behind by a failed `devcontainer up`.
workspace_containers() {
    docker ps -aq --filter "label=devcontainer.local_folder=$ws"
}

# Prints the id of the workspace's running dev container.
current_container() {
    docker ps -q --filter "label=devcontainer.local_folder=$ws"
}

# Prints the ids of the images the CLI has built for the workspace, newest
# first.
workspace_images() {
    docker images -q --filter "reference=$images_ref"
}

feature_volume() {
    docker inspect "$1" \
        --format '{{range .Mounts}}{{if eq .Type "volume"}}{{println .Name}}{{end}}{{end}}' |
        grep "^$feature-"
}

up() {
    devcontainer up --workspace-folder "$ws" "$@"
}

run_in_container() {
    devcontainer exec --workspace-folder "$ws" --remote-env "REBUILD_TOKEN=$token" \
        bash ".devcontainer/$1"
}

cleanup() {
    local id
    for id in $(workspace_containers); do
        if [ -z "$volume" ]; then
            volume=$(feature_volume "$id" || true)
        fi
        docker rm -f "$id" >/dev/null 2>&1 || true
    done
    # Newest first, so that an image goes before the image it was built on.
    for id in $images $(workspace_images); do
        docker image rm "$id" >/dev/null 2>&1 || true
    done
    if [ -n "$(workspace_images)" ]; then
        echo "Images left behind:" >&2
        docker images --filter "reference=$images_ref" >&2
    fi
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

echo "::group::Create container and write data"
if [ -f "$fixture/before.devcontainer.json" ]; then
    cp "$fixture/before.devcontainer.json" "$ws/.devcontainer/devcontainer.json"
fi
up
first=$(current_container)
# The rebuild moves the image names to the new build, so cleanup could no
# longer find this build's images by name.
images+=" $(workspace_images)"
volume=$(feature_volume "$first")
run_in_container before.sh
echo "::endgroup::"

echo "::group::Rebuild container and check data"
cp "$fixture/devcontainer.json" "$ws/.devcontainer/devcontainer.json"
up --remove-existing-container
second=$(current_container)
run_in_container after.sh
echo "::endgroup::"

# shellcheck source=SCRIPTDIR/rebuild-lib.sh
source "$repo/scripts/rebuild-lib.sh"
check "rebuild created a new container" test "$first" != "$second"
check "new container uses the same volume" test "$(feature_volume "$second")" = "$volume"
report_results
