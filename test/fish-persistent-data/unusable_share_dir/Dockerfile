FROM mcr.microsoft.com/devcontainers/base:debian
# Home directories in which a feature or Dockerfile step running as root
# created ~/.local/share or ~/.local. The test script runs the installed
# onCreate.sh with HOME pointing at them, because the same state in vscode's
# own home would fail container creation before the test could run. Fixtures
# owned by vscode are created by the test script.
RUN mkdir -p /opt/broken-homes/share/.local/share/fish \
    && mkdir -p /opt/broken-homes/local/.local
