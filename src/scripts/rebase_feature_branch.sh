#!/bin/bash

# Default values from arguments
FEATURE_BRANCH=$1
MAIN_BRANCH=$2
REMOTE=origin

# Check if FEATURE_BRANCH is empty
if [ -z "$FEATURE_BRANCH" ]; then
    if [ -n "$GITHUB_HEAD_REF" ]; then
        # If running as part of a PR, use the PR head ref
        FEATURE_BRANCH="$GITHUB_HEAD_REF"
    else
        echo "No feature branch specified and not running in a PR context. Exiting."
        echo "Usage: $0 <feature-branch> <main-branch>"
        exit 1
    fi
fi

# Check if MAIN_BRANCH is empty, default to 'main'
if [ -z "$MAIN_BRANCH" ]; then
    MAIN_BRANCH="main"
fi

echo "Feature branch: $FEATURE_BRANCH"
echo "Main branch: $MAIN_BRANCH"

# Fetch the latest changes from remote
echo "Fetching latest changes..."
git fetch "$REMOTE"

# Switch to the feature branch
echo "Switching to feature branch: $FEATURE_BRANCH"
git checkout "$FEATURE_BRANCH" || {
    echo "Failed to checkout feature branch $FEATURE_BRANCH"
    exit 1
}

# Perform the rebase
echo "Rebasing $FEATURE_BRANCH onto $MAIN_BRANCH..."
git rebase "$REMOTE/$MAIN_BRANCH" || {
    echo "Rebase failed."
    exit 1
}

# Push the rebased branch (if needed)
echo "Pushing the rebased feature branch..."
git push "$REMOTE" "$FEATURE_BRANCH" || {
    echo "Failed to push the rebased feature branch."
    exit 1
}

echo "Rebase successful."