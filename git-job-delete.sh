#!/bin/bash

GITHUB_USER="akylgit"
REPO="flask-helm-deploy"
# Define both actual names or paths shown in GitHub API
WORKFLOW_IDENTIFIERS=("CI/CD Pipeline" ".github/workflows/ci.yaml")
KEEP=2
TOKEN="${GITHUB_TOKEN:-YOUR_GITHUB_PAT}"

for IDENTIFIER in "${WORKFLOW_IDENTIFIERS[@]}"; do
  echo "🔎 Checking workflow: $IDENTIFIER"

  # Match either by 'name' or 'path'
  WORKFLOW_ID=$(curl -s -H "Authorization: token $TOKEN" \
    https://api.github.com/repos/$GITHUB_USER/$REPO/actions/workflows | \
    jq -r ".workflows[] | select(.name==\"$IDENTIFIER\" or .path==\"$IDENTIFIER\") | .id")

  if [[ -z "$WORKFLOW_ID" ]]; then
    echo "❌ Workflow \"$IDENTIFIER\" not found."
    continue
  fi

  # Get run IDs to delete (skipping latest $KEEP)
  RUN_IDS=$(curl -s -H "Authorization: token $TOKEN" \
    "https://api.github.com/repos/$GITHUB_USER/$REPO/actions/workflows/$WORKFLOW_ID/runs?per_page=100" | \
    jq -r ".workflow_runs | .[$KEEP:] | .[].id")

  for run_id in $RUN_IDS; do
    echo "🗑️ Deleting run ID: $run_id"
    resp=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE \
      -H "Authorization: token $TOKEN" \
      "https://api.github.com/repos/$GITHUB_USER/$REPO/actions/runs/$run_id")

    if [[ "$resp" == "204" ]]; then
      echo "✅ Deleted run ID: $run_id"
    else
      echo "❌ Failed to delete run ID: $run_id (HTTP $resp)"
    fi
  done

  echo "✅ Finished cleanup for: $IDENTIFIER"
  echo
done

echo "🏁 Deletion script finished for all workflows."

