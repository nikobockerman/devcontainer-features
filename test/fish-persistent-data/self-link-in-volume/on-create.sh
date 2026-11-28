#!/bin/bash
set -euo pipefail

mountpoint=/mnt/fish-persistent-data

fish -c "history append 'echo before-rebuild-$REBUILD_TOKEN'"

# Plant what versions 2.0.0 to 2.0.3 left in the volume after their
# onCreate ran three times against a persisted home directory: the second
# run moved the data dir symlink aside to fish-old, and the third moved the
# new one into fish-old, which follows the link into the volume.
ln -s "$mountpoint" "$mountpoint/fish"
