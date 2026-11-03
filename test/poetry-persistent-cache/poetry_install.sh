#!/bin/bash

# shellcheck source=/dev/null
source dev-container-features-test-lib
# shellcheck source=SCRIPTDIR/checks.sh
source "$(dirname "$0")/checks.sh"

check_feature_setup

check "install poetry" pipx install --quiet poetry

project=$(mktemp -d)
cd "$project" || exit 1
cat > pyproject.toml <<'TOML'
[tool.poetry]
package-mode = false

[tool.poetry.dependencies]
python = "^3.9"
idna = "*"
TOML

check "poetry uses the volume as cache dir" test "$(poetry config cache-dir)" = "$mountpoint"
check "poetry install" poetry install --no-interaction
check "downloaded package is cached on the volume" \
    test -n "$(find "$mountpoint" -name 'idna-*.whl' -print -quit)"
check "cache contents are owned by the user" \
    test -z "$(find "$mountpoint" ! -user "$user" -print -quit)"

# virtualenvs.path defaults to {cache-dir}/virtualenvs, so the venv also lives
# on the persistent volume.
venv=$(poetry env info --path)
check "virtualenv is created inside the persistent cache" \
    test "${venv#"$mountpoint"/virtualenvs/}" != "$venv"

reportResults
