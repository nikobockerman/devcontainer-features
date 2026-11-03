#!/bin/bash

# Executed against an auto-generated devcontainer.json that includes the
# 'fish-persistent-data' Feature with default options, once per base image in
# the CI matrix. Scenarios in scenarios.json cover specific image states.
#
# See: https://github.com/devcontainers/cli/blob/main/docs/features/test.md
#
# Run locally with:
#
#    devcontainer features test -f fish-persistent-data --skip-scenarios \
#        -i mcr.microsoft.com/devcontainers/base:debian .

# shellcheck source=/dev/null
source dev-container-features-test-lib
# shellcheck source=SCRIPTDIR/checks.sh
source "$(dirname "$0")/checks.sh"

check_feature_setup

reportResults
