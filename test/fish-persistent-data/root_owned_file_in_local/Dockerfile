FROM mcr.microsoft.com/devcontainers/base:debian
# A root-owned file inside the user's ~/.local, as left behind by a feature or
# Dockerfile step that runs as root (issue #162).
RUN mkdir -p ~vscode/.local/share/man/man1 \
    && chown -R vscode:vscode ~vscode/.local \
    && touch ~vscode/.local/share/man/man1/bandit.1
