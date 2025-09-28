#!/bin/bash
touch $HOME/.gitconfig

echo "Set git safe.directory: ${{ github.workspace }}"
git config --global --unset-all safe.directory "${{ github.workspace }}"
git config --global --add safe.directory "${{ github.workspace }}"

echo "Set git init.defaultBranch: ${{ github.event.repository.default_branch }}"
# https://github.com/actions/checkout/issues/430#issuecomment-810950736
git config --global init.defaultBranch ${{ github.event.repository.default_branch }}
