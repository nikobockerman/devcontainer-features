#!/bin/sh
set -e

echo "Enabling debug output to investigate why fish-persistent-data fails to install properly on VSCode Recovery Containers"
set -x

content_base_dir=/usr/local/share/github-nikobockerman/devcontainer-features
feature_content_dir=$content_base_dir/fish-persistent-data
on_create_script=$feature_content_dir/onCreate.sh

# Prepare on-create script
mkdir -p "$feature_content_dir"
cp onCreate.sh "$on_create_script"
chmod +x "$on_create_script"

env|sort || true
umask || true
ls -la /usr || true
ls -la /usr/local || true
ls -la /usr/local/share || true
ls -la /usr/local/share/github-nikobockerman || true
ls -la /usr/local/share/github-nikobockerman/devcontainer-features || true
ls -la /usr/local/share/github-nikobockerman/devcontainer-features/fish-persistent-data || true
