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
# the test. The fixture's devcontainer.json names the feature "@FEATURE@",
# a placeholder that the script fills in for each container with the
# version that container uses.
#
# To test an upgrade, name published versions of the feature after the
# fixture. The first container then uses the first of them, each further one
# replaces the feature in a rebuild in turn, and the last rebuild uses the
# version in the repository. Only the first container runs before.sh and
# only the last one runs after.sh, so the data has to survive every step in
# between. A version is any tag that is published for the feature, such as
# 2.0.3 or 1 (the newest 1.x).
#
# Usage: scripts/test-rebuild.sh <feature> [fixture [version...]]

set -euo pipefail

feature=${1:?usage: $0 <feature> [fixture [version...]]}
repo=$(cd "$(dirname "$0")/.." && pwd)
fixture=$repo/test/$feature/${2:-rebuild}
shift $(($# < 2 ? $# : 2))
if [ ! -d "$fixture" ]; then
    echo "No rebuild fixture at $fixture" >&2
    exit 1
fi
published_ref=ghcr.io/nikobockerman/devcontainer-features/$feature
# The published versions to start from, oldest first; the repository version
# comes after them.
versions=("$@")

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

# Writes the fixture's devcontainer.json to the workspace with its
# @FEATURE@ placeholder filled in: the published version $1 of the feature
# if one is given, otherwise the repository version that is copied next to
# it. Every container uses the same config path rather than one passed with
# --config, because the CLI derives the volume name from that path and the
# rebuilt container must get the same volume.
use_config() {
    local ref=./$feature
    if [ -n "${1:-}" ]; then
        ref=$published_ref:$1
    fi
    if ! grep -qF @FEATURE@ "$fixture/devcontainer.json"; then
        echo "$fixture/devcontainer.json has no @FEATURE@ placeholder" >&2
        exit 1
    fi
    sed "s|@FEATURE@|$ref|" "$fixture/devcontainer.json" >"$ws/.devcontainer/devcontainer.json"
}

# Prints what a step installs: published version $1 of the feature, or the
# repository version when $1 is empty.
describe() {
    if [ -n "$1" ]; then
        echo "$feature $1"
    else
        echo "the repository version"
    fi
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

echo "::group::Create container with $(describe "${versions[0]:-}") and write data"
use_config "${versions[0]:-}"
up
containers=("$(current_container)")
volume=$(feature_volume "${containers[0]}")
# The volume of each container, read while it exists: the next rebuild
# removes it.
volumes=("$volume")
# A rebuild moves the image names to the new build, so cleanup could no
# longer find this build's images by name. Newest first, like
# workspace_images, also across builds.
images="$(workspace_images) $images"
run_in_container before.sh
echo "::endgroup::"

# Every published version after the first one, then the repository version
# (the empty string).
for version in "${versions[@]:1}" ""; do
    echo "::group::Rebuild container with $(describe "$version")"
    use_config "$version"
    up --remove-existing-container
    container=$(current_container)
    containers+=("$container")
    volumes+=("$(feature_volume "$container" || true)")
    images="$(workspace_images) $images"
    echo "::endgroup::"
done

echo "::group::Check data"
run_in_container after.sh
echo "::endgroup::"

# shellcheck source=SCRIPTDIR/rebuild-lib.sh
source "$repo/scripts/rebuild-lib.sh"
for ((i = 1; i < ${#containers[@]}; i++)); do
    check "rebuild $i created a new container" \
        test "${containers[i]}" != "${containers[i - 1]}"
    check "container after rebuild $i uses the same volume" \
        test "${volumes[i]}" = "$volume"
done
report_results
