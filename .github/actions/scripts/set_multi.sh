#!/bin/bash
# Argument validation check
if [ "$#" -gt 1 ]; then
    echo "Usage: $0 [<home_dir>]"
    exit 1
fi

mydir="$(dirname "$(readlink -f "$0")")"
source "$mydir/set_home.sh" "$@"
source "$mydir/set_git_config.sh"
