#!/bin/bash

set -euo pipefail

case "$CACHE_MODE" in
  prepare|use)
    ;;
  *)
    echo "::error::Unknown cache mode: $CACHE_MODE"
    exit 1
    ;;
esac

echo "::group::Outputs from init"
{
  echo "mise-version=${MISE_VERSION}"
} | tee -a "$GITHUB_OUTPUT"
echo "::endgroup::"
