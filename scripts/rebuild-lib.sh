#!/bin/bash

# Minimal stand-in for dev-container-features-test-lib, which only exists
# inside containers created by `devcontainer features test`.

failed=0

check() {
    local label=$1
    shift
    if "$@"; then
        echo "✅ $label"
    else
        echo "❌ $label"
        failed=1
    fi
}

report_results() {
    if [ "$failed" -ne 0 ]; then
        echo "Some checks failed"
        exit 1
    fi
    echo "All checks passed"
}
