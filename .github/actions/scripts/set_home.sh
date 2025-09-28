#!/bin/bash
# Argument validation check
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 [<home_dir>]"
    exit 1
fi

# Set HOME variable
if [[ ! -z "$1" ]]; then
  xHOME="$1"
elif [[ $EUID -eq 0 ]]; then
  xHOME="/root"
else
  homedir=~
  if ! eval xHOME=$homedir; then
    xHOME="/home/$(whoami)"
  fi
fi
#export HOME="$xHOME"
echo "HOME=$xHOME" >> $GITHUB_ENV
