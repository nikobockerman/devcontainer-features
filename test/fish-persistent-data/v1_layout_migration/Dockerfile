FROM mcr.microsoft.com/devcontainers/base:debian
# Docker copies image content at the mount target into a new, empty named
# volume. This pre-populates the volume with the 1.x layout, where fish data
# lived in a 'fish' subdirectory.
RUN mkdir -p /mnt/fish-persistent-data/fish \
    && echo '- cmd: echo from-v1' > /mnt/fish-persistent-data/fish/fish_history \
    && chown -R vscode:vscode /mnt/fish-persistent-data
