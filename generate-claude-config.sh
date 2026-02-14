#!/usr/bin/env bash
set -euo pipefail

WIKI_PATH="${1:-$HOME/vimwiki}"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

cat <<EOF
## Status Reporting
- For each task, the main agent should periodically write updates to a wip file in \`${WIKI_PATH}/wip/\`.
- If the initial prompt specifies a task definition file path, use that file as the wip file. Only create a new file if no task definition file is provided.
- New wip files should have a sensible, task-appropriate name, created at the beginning of the task.
- The format of this file is determined by the ${REPO_DIR}/templates/task.wiki
- **Every time you update the WIP file, also update the "Last Updated Date/Time" field to the current date/time.**
- The **Status** field should be flexible but meaningful. Good examples: \`Planning\`, \`Researching\`, \`Implementing\`, \`Testing\`, \`CI-Checks\`, \`Waiting for Review\`. Never set status to \`Complete\` — only the user decides when a task is complete.
- Set the **Tmux Window** field to the window number only (not the name). Get it with: \`tmux display-message -p '#I'\`
EOF
