#!/bin/bash

# List of repositories (update this with your repo URLs)
REPOS=(
    "https://github.com/user/repo1.git"
    "https://github.com/user/repo2.git"
)

# Branches to compare
BRANCH1="main"
BRANCH2="feature-branch"

# Directory to store cloned repositories
WORK_DIR="cloned_repos"

# Create working directory
mkdir -p $WORK_DIR
cd $WORK_DIR

# Loop through repositories
for REPO in "${REPOS[@]}"; do
    REPO_NAME=$(basename -s .git "$REPO")
    echo "Cloning repository: $REPO_NAME"
    
    # Clone the repository
    if [ ! -d "$REPO_NAME" ]; then
        git clone "$REPO" "$REPO_NAME"
    else
        echo "Repository $REPO_NAME already exists. Pulling latest changes..."
        cd "$REPO_NAME"
        git pull
        cd ..
    fi

    # Enter the repository directory
    cd "$REPO_NAME"

    # Fetch all branches
    git fetch origin

    # Check out the first branch
    echo "Checking out branch: $BRANCH1"
    git checkout $BRANCH1
    git pull origin $BRANCH1

    # Check out the second branch
    echo "Checking out branch: $BRANCH2"
    git checkout $BRANCH2
    git pull origin $BRANCH2

    # Compare the branches
    echo "Comparing branches $BRANCH1 and $BRANCH2 in $REPO_NAME:"
    git log "$BRANCH1..$BRANCH2" --oneline

    # Return to the working directory
    cd ..
    echo "--------------------------------------------"
done

echo "All repositories processed."
