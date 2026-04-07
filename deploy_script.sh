#!/bin/bash
set -euo pipefail

# Step 1: Initialize repository for reptrack
TARGET_DIR="$HOME/practify"
mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

# Step 2: Sync repository (clone/pull latest code)
if [ ! -d ".git" ]; then
    echo "--- Cloning ---"
    git clone https://github.com/Moin-A/Practify.git .
else
    echo "--- Syncing ---"
    git fetch origin
    git reset --hard origin/main
fi

# Step 3: Docker build
echo "--- Docker Login ---"
echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin

# Step 4: Docker push
echo "--- Building & Pushing ---"
docker build --network=host -t $DOCKER_USERNAME/practify:latest .
docker push $DOCKER_USERNAME/practify:latest

# Step 5: Find Kubernetes manifest

# Step 6: Kubernetes apply

# Step 7: Database migration

echo "Deploy script executed successfully!"
