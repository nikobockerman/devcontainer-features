# shellcheck shell=bash

# Assertions shared by test.sh and the scenario scripts. Source this after
# dev-container-features-test-lib, which provides 'check'.

user=$(id -un)
group=$(id -gn)
mountpoint=/mnt/yarn-persistent-cache

check_feature_setup() {
    echo "User: $user, group: $group"
    stat "$mountpoint"

    check "mount exists" grep -q " $mountpoint " /proc/mounts
    check "YARN_ENABLE_GLOBAL_CACHE is false" test "$YARN_ENABLE_GLOBAL_CACHE" = false
    check "YARN_CACHE_FOLDER points to mountpoint" test "$YARN_CACHE_FOLDER" = "$mountpoint"

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
