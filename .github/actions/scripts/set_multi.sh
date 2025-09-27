#!/bin/bash
# Argument validation check
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 [<home_dir>]"
    exit 1
fi

source .github/actions/scripts/set_home.sh $@
source .github/actions/scripts/set_git_safedir.sh
