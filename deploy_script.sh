#!/bin/bash
set -euo pipefail

# Step 1: Initialize repository for reptrack
TARGET_DIR="$HOME/reptrack"
mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

# Step 2: Sync repository (clone/pull latest code)
if [ -d ".git" ]; then
    echo "--- Syncing ---"
    git fetch origin
    git reset --hard origin/main
else
    echo "--- Cloning ---"
    git init
    git remote add origin https://github.com/Moin-A/reptrack.git
    git fetch origin
    git reset --hard origin/main
fi

# Step 3: Docker build
echo "--- Docker Login ---"
echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin

# Step 4: Docker push
echo "--- Building & Pushing ---"
docker build --network=host -t $DOCKER_USERNAME/reptrack:latest .
docker push $DOCKER_USERNAME/reptrack:latest

# Step 5: Find Kubernetes manifest

DEPLOY_YAML=$(find . -regex ".*\(deployment.*kube\|kube.*deployment\).*\.yaml"  | head -n 1)
WORKER_YAML=$(find . -regex ".*\(worker.*kube\|kube.*worker\).*\.yaml"  | head -n 1)

if [ -z "$DEPLOY_YAML" ] || [ -z "$WORKER_YAML" ]; then
            echo "❌ ERROR: Manifests not found!"
            exit 1
fi


# Step 6: Kubernetes apply
 echo "--- Applying Manifests ---"
 kubectl apply -f "$DEPLOY_YAML"
 kubectl apply -f "$WORKER_YAML"

# Step 7: Database migration

echo "Deploy script executed successfully!"
