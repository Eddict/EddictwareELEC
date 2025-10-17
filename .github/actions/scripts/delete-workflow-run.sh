#!/usr/bin/env bash
# Lightweight helper for composite action: this script is run as the 'main' command
# for the delete-workflow-run composite action. Keep it small and safe; real deletion
# happens in the action post step via the action's octokit call.

set -euo pipefail

echo "delete-workflow-run: placeholder main script"
echo "GITHUB_REPOSITORY=${GITHUB_REPOSITORY:-}", "GITHUB_RUN_ID=${GITHUB_RUN_ID:-}"

# No-op: the JS action's main step writes run id into GITHUB_STATE and the post step
# will perform the delete. Replace or extend this script if you need to perform
# pre-delete tasks.

exit 0
