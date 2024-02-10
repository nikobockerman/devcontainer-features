#!/bin/sh
set -e

content_base_dir=/usr/local/share/github-nikobockerman/devcontainer-features
feature_content_dir=$content_base_dir/fish-persistent-data
on_create_script=$feature_content_dir/onCreate.sh

# Prepare on-create script
mkdir -p "$feature_content_dir"
cp onCreate.sh "$on_create_script"
chmod +x "$on_create_script"
