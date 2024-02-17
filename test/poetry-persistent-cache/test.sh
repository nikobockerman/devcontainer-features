#!/bin/bash

# This test file will be executed against an auto-generated devcontainer.json that
# includes the 'poetry-persistent-cache' Feature with no options.
#
# For more information, see: https://github.com/devcontainers/cli/blob/main/docs/features/test.md
#
# Eg:
# {
#    "image": "<..some-base-image...>",
#    "features": {
#      "poetry-persistent-cache": {}
#    },
#    "remoteUser": "root"
# }
#
# Thus, the value of all options will fall back to the default value in the
# Feature's 'devcontainer-feature.json'.
#
# These scripts are run as 'root' by default. Although that can be changed
# with the '--remote-user' flag.
#
# This test can be run with the following command:
#
#    devcontainer features test                    \
#               --features poetry-persistent-cache \
#               --remote-user root                 \
#               --skip-scenarios                   \
#               --base-image mcr.microsoft.com/devcontainers/base:ubuntu \
#               /path/to/this/repo

# Optional: Import test library bundled with the devcontainer CLI
# See https://github.com/devcontainers/cli/blob/HEAD/docs/features/test.md#dev-container-features-test-lib
# Provides the 'check' and 'reportResults' commands.
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Feature-specific tests
# The 'check' command comes from the dev-container-features-test-lib. Syntax is...
# check <LABEL> <cmd> [args...]
user=$(id -un)
group=$(id -gn)
mountpoint=/mnt/poetry-persistent-cache

echo "Testing poetry-persistent-cache feature"
echo "User: $user"
echo "Group: $group"
echo "Mountpoint: $mountpoint"

echo "Stat mountpoint:"
stat "$mountpoint"

check "validate mount exists" grep $mountpoint /proc/mounts >/dev/null
check "validate environment variable is set" test -n "$POETRY_CACHE_DIR"
check "valida environment variable is set to mountpoint" test "$POETRY_CACHE_DIR" = "$mountpoint"

check "validate mountpoint user" test "$(stat -c '%U' "$mountpoint")" = "$user"
check "validate mountpoint group" test "$(stat -c '%G' "$mountpoint")" = "$group"
perm=$(stat -c '%a' "$mountpoint")
check "validate mountpoint permissions" test "${perm:0:1}" = 7

# Report result
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults
