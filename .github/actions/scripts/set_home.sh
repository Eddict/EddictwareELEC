#!/bin/bash

if [[ $EUID -eq 0 ]]; then
  HOME="/root"
else
  HOME="/home/$(whoami)"
  homedir=~
  eval HOME=$homedir
fi
export HOME="$HOME"
