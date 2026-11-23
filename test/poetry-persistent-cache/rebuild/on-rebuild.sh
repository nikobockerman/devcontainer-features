#!/bin/bash

# shellcheck source=SCRIPTDIR/../../../scripts/rebuild-lib.sh
source "$(dirname "$0")/rebuild-lib.sh"

cd project || exit 1
cached_wheels() {
    find "$POETRY_CACHE_DIR" -name 'idna-*.whl' -exec stat -c '%i %Y %n' {} +
}

check "cache from before the rebuild is present" \
    test "$(cat "$POETRY_CACHE_DIR/rebuild-token")" = "$REBUILD_TOKEN"
check "cached wheel is the same file" test "$(cached_wheels)" = "$(cat ../wheels-before)"
check "poetry uses the virtualenv from before the rebuild" \
    test "$(poetry env info --path)" = "$(cat ../venv-before)"
check "installed package is importable" poetry run python -c 'import idna'

# The reused virtualenv already has idna, so poetry install would not need the
# wheel. Without the virtualenv it has to install idna again.
check "remove the virtualenv" poetry env remove --all
check "poetry install into a new virtualenv" poetry install --no-interaction
check "poetry install reused the cached wheel" \
    test "$(cached_wheels)" = "$(cat ../wheels-before)"
check "package is importable from the new virtualenv" poetry run python -c 'import idna'

report_results
