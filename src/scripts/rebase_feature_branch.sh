#!/bin/bash

# Variables
FEATURE_BRANCH=$1
MAIN_BRANCH=$2
REMOTE="origin"

# Function to display usage
function usage {
    echo "Usage: $0 <feature-branch> <main-branch>"
    exit 1
}

# Check if both arguments are provided
if [ -z "$FEATURE_BRANCH" ] || [ -z "$MAIN_BRANCH" ]; then
    usage
fi

# Fetch the latest changes
echo "Fetching latest changes..."
git fetch "$REMOTE" || { echo "Failed to fetch from remote"; exit 1; }

# Checkout the feature branch
echo "Switching to feature branch: $FEATURE_BRANCH"
git checkout "$FEATURE_BRANCH" || { echo "Failed to checkout feature branch"; exit 1; }

# Rebase the feature branch onto the main branch
echo "Rebasing $FEATURE_BRANCH onto $MAIN_BRANCH..."
git rebase "$REMOTE/$MAIN_BRANCH" || {
    echo "Rebase encountered conflicts. Aborting."
    git rebase --abort
    exit 1
}

# Push the rebased branch back to the remote
echo "Pushing rebased branch to remote..."
git push --force-with-lease "$REMOTE" "$FEATURE_BRANCH" || { echo "Failed to push rebased branch"; exit 1; }

echo "Rebase completed successfully!"
