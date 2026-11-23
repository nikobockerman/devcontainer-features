#!/bin/bash
set -euo pipefail

# The project lives in the bind-mounted workspace, like a real one, so it is
# there again after the rebuild. Only the cache volume carries Yarn's state.
# Corepack runs the Yarn version that package.json names.
export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
mkdir -p project
cd project
cat > package.json <<'JSON'
{ "name": "rebuild-test", "private": true, "packageManager": "yarn@4.18.1" }
JSON
# An empty lockfile makes this directory a project root of its own.
touch yarn.lock
corepack yarn add is-number@7.0.0
# Yarn also copies what it downloads to a mirror in the home directory.
# on-rebuild.sh checks that the new container starts without it, which
# only means something if this is where the mirror is.
if [ ! -d "$HOME/.yarn/berry/cache" ]; then
    echo "Yarn's mirror is not at $HOME/.yarn/berry/cache" >&2
    exit 1
fi

echo "$REBUILD_TOKEN" > "$YARN_CACHE_FOLDER/rebuild-token"
find "$YARN_CACHE_FOLDER" -name 'is-number-npm-7.0.0-*.zip' -exec stat -c '%i %Y %n' {} + > ../zip-before
