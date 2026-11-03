FROM mcr.microsoft.com/devcontainers/base:debian
# A root-owned file inside the user's ~/.local, as left behind by a feature or
# Dockerfile step that runs as root (issue #162).
RUN mkdir -p /home/vscode/.local/share/man/man1 \
    && chown -R vscode:vscode /home/vscode/.local \
    && touch /home/vscode/.local/share/man/man1/bandit.1
