#!/bin/bash
set -euo pipefail

# The project lives in the bind-mounted workspace, like a real one, so it is
# there again after the rebuild. Only the cache volume carries Poetry's state.
mkdir -p project
cd project
cat > pyproject.toml <<'TOML'
[tool.poetry]
package-mode = false

[tool.poetry.dependencies]
python = "^3.9"
idna = "*"
TOML
poetry install --no-interaction

echo "$REBUILD_TOKEN" > "$POETRY_CACHE_DIR/rebuild-token"
find "$POETRY_CACHE_DIR" -name 'idna-*.whl' -exec stat -c '%i %Y %n' {} + > ../wheels-before
poetry env info --path > ../venv-before
