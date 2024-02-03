#!/bin/bash

# This test file will be executed against an auto-generated devcontainer.json that
# includes the 'fish-persistent-data' Feature with no options.
#
# For more information, see: https://github.com/devcontainers/cli/blob/main/docs/features/test.md
#
# Eg:
# {
#    "image": "<..some-base-image...>",
#    "features": {
#      "fish-persistent-data": {}
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
#    devcontainer features test                 \
#               --features fish-persistent-data \
#               --remote-user root              \
#               --skip-scenarios                \
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
mountpoint=/mnt/fish-persistent-data
datadir=$HOME/.local/share/fish
persistentdir=$mountpoint/fish

echo "Testing fish-persistent-data feature"
echo "User: $user"
echo "Group: $group"
echo "Mountpoint: $mountpoint"
echo "Data dir: $datadir"
echo "Persistent dir: $persistentdir"

echo "Stat datadir:"
stat "$datadir"

echo "Stat persistentdir:"
stat "$persistentdir"

check "validate mount exists" grep $mountpoint /proc/mounts >/dev/null

check "validate symlink exists" test -L "$datadir"
check "validate data symlink exists" test "$(readlink "$datadir")" = "$persistentdir"

check "validate persistent dir user" test "$(stat -c '%U' "$persistentdir")" = "$user"
check "validate persistent dir group" test "$(stat -c '%G' "$persistentdir")" = "$group"
perm=$(stat -c '%a' "$persistentdir")
check "validate persistent dir permissions" test "${perm:0:1}" = 7

dir=$datadir
while [ "$dir" != "$HOME" ]; do
    check "validate $dir user permissions" test "$(stat -c '%U' "$dir")" = "$user"
    check "validate $dir group permissions" test "$(stat -c '%G' "$dir")" = "$group"
    perm=$(stat -c '%a' "$dir")
    check "validate $dir permissions" test "${perm:0:1}" = 7
    dir=$(dirname "$dir")
done

# Report result
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults
