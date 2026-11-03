# shellcheck shell=bash

# Assertions shared by test.sh and the scenario scripts. Source this after
# dev-container-features-test-lib, which provides 'check'.

user=$(id -un)
group=$(id -gn)
mountpoint=/mnt/poetry-persistent-cache

check_feature_setup() {
    echo "User: $user, group: $group"
    stat "$mountpoint"

    check "mount exists" grep -q " $mountpoint " /proc/mounts
    check "POETRY_CACHE_DIR points to mountpoint" test "$POETRY_CACHE_DIR" = "$mountpoint"

    check "mountpoint user" test "$(stat -c '%U' "$mountpoint")" = "$user"
    check "mountpoint group" test "$(stat -c '%G' "$mountpoint")" = "$group"
    local perm
    perm=$(stat -c '%a' "$mountpoint")
    check "mountpoint permissions" test "${perm:0:1}" = 7

    local probe
    probe=$mountpoint/write-probe-$RANDOM
    check "user can write to the volume" touch "$probe"
    rm -f "$probe"
}

# Installs poetry from the given pip requirement, such as 'poetry<2', and
# checks that installing a project caches its packages and virtualenv on the
# volume.
check_poetry_install() {
    local requirement=$1
    check "install $requirement" pipx install --quiet "$requirement"
    poetry --version

    local project
    project=$(mktemp -d)
    cd "$project" || exit 1
    cat >pyproject.toml <<'TOML'
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

    # virtualenvs.path defaults to {cache-dir}/virtualenvs, so the venv also
    # lives on the persistent volume.
    local venv
    venv=$(poetry env info --path)
    check "virtualenv is created inside the persistent cache" \
        test "${venv#"$mountpoint"/virtualenvs/}" != "$venv"
}
