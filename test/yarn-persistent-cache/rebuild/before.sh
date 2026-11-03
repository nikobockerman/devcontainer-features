#!/bin/bash
set -euo pipefail

echo "$REBUILD_TOKEN" > "$YARN_CACHE_FOLDER/rebuild-token"
