FROM mcr.microsoft.com/devcontainers/base:debian
# Fish data in the image, next to a fish-old that an earlier move left aside.
# The feature must keep both, so it has to pick another name for the current
# data dir.
RUN mkdir -p ~vscode/.local/share/fish ~vscode/.local/share/fish-old \
    && echo '- cmd: echo from-image' > ~vscode/.local/share/fish/fish_history \
    && echo '- cmd: echo from-earlier' > ~vscode/.local/share/fish-old/fish_history \
    && chown -R vscode:vscode ~vscode/.local
