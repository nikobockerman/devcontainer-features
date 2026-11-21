FROM mcr.microsoft.com/devcontainers/base:debian
# Fish data that exists in the image before the feature replaces the data dir
# with a symlink.
RUN mkdir -p ~vscode/.local/share/fish \
    && echo '- cmd: echo from-image' > ~vscode/.local/share/fish/fish_history \
    && chown -R vscode:vscode ~vscode/.local
