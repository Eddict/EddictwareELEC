#!/bin/bash

touch $HOME/.gitconfig
git config --global --unset-all safe.directory "${{ github.workspace }}"
git config --global --add safe.directory "${{ github.workspace }}"
