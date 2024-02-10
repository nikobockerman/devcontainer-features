
# Fish - persistent data (fish-persistent-data)

A feature that provides persistent data for Fish shell

## Example Usage

```json
"features": {
    "ghcr.io/nikobockerman/devcontainer-features/fish-persistent-data:2": {}
}
```



## Major changes in versions

### 2.0.0

- Move data from `/mnt/fish-persistent-history/fish` directory to the root of
  the mount point. This was done to simplify the logic a little bit and because
  the subdirectory doesn't add any value.
  A migration is included which moves the data to new location so that it
  remains available when this new version is updated to for a container that
  already had data created in the persistent volume by 1.* version
- The logic for creating the symlink is moved from install.sh to a script that
  is run as onCreateCommand. This is done because VSCode Recovery container
  runs the install.sh but doesn't add the mount and doesn't run
  onCreateCommand. Therefore, in this scenario the fish data directory symlink
  was pointing to a non-existing location and fish wouldn't be able to use it
  for anything, not even as a non-persistent data directory. This only affects
  users who have fish-persistent-data as enabled in VSCode through
  `dev.containers.defaultFeatures` setting.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/nikobockerman/devcontainer-features/blob/main/src/fish-persistent-data/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
