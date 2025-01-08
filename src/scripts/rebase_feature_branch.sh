#!/bin/bash

# Check if the feature branch was passed as an argument
if [ -z "$FEATURE_BRANCH" ]; then
  # If no feature branch argument is provided, get the current branch from the SCM system (Git)
  FEATURE_BRANCH=$(git symbolic-ref --short HEAD)
  echo "No feature branch provided. Using current branch: $FEATURE_BRANCH"
fi

# Get the main branch (passed as an argument or hardcoded)
MAIN_BRANCH=${1:-main}

echo "Feature Branch: $FEATURE_BRANCH"
echo "Main Branch: $MAIN_BRANCH"

# Fetch the latest changes from the remote
git fetch origin

# Checkout the main branch
git checkout $MAIN_BRANCH
git pull origin $MAIN_BRANCH

# Rebase the feature branch onto the main branch
git checkout $FEATURE_BRANCH
git pull origin $FEATURE_BRANCH
git rebase $MAIN_BRANCH

# Push the rebased feature branch
git push origin $FEATURE_BRANCH --force

echo "Rebase complete."