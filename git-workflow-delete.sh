#!/bin/bash

WORKFLOW_NAME="Build, Push & Update Deployment to Argo CD"
KEEP=5

# Get all run IDs for the workflow, skipping the latest $KEEP
gh run list --workflow "$WORKFLOW_NAME" --limit 100 --json databaseId | \
jq -r ".[${KEEP}:] | .[].databaseId" | while read run_id; do
  echo "Deleting run ID: $run_id"
  gh run delete "$run_id" --confirm
done
