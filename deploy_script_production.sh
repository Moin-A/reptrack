#!/bin/bash
set -euo pipefail

TARGET_DIR="$HOME/reptrack"
IMAGE="$DOCKER_USERNAME/reptrack"
BRANCH="production"

mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

if [ -d ".git" ]; then
    echo "--- Syncing ($BRANCH) ---"
    git fetch origin
    git reset --hard origin/$BRANCH
else
    echo "--- Cloning ($BRANCH) ---"
    git init
    git remote add origin https://github.com/Moin-A/reptrack.git
    git fetch origin
    git reset --hard origin/$BRANCH
fi

TAG=$(git rev-parse --short HEAD)
echo "--- Image tag: $TAG ---"

echo "--- Docker Login ---"
echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin

echo "--- Building & Pushing ---"
docker build --network=host -t "$IMAGE:$TAG" -t "$IMAGE:latest" .
docker push "$IMAGE:$TAG"
docker push "$IMAGE:latest"

# Find production manifests (matches .yml or .yaml)
DEPLOY_YAML=$(find . -regex ".*production.*deployment.*\.ya?ml" | head -n 1)
WORKER_YAML=$(find . -regex ".*production.*worker.*\.ya?ml" | head -n 1)

# Local k3s config — this runs ON EC2
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

if [ -z "$DEPLOY_YAML" ]; then
    echo "❌ ERROR: Deployment manifest not found!"
    exit 1
fi

# Apply manifests — creates resources first run, updates structure after
echo "--- Applying Manifests ---"
kubectl apply -f "$DEPLOY_YAML"
if [ -n "$WORKER_YAML" ]; then
    kubectl apply -f "$WORKER_YAML"
fi

# Force rollout with the immutable SHA tag
echo "--- Deploying $TAG ---"
kubectl set image deployment/reptrack-api reptrack-api="$IMAGE:$TAG" -n reptrack
if [ -n "$WORKER_YAML" ]; then
    kubectl set image deployment/reptrack-worker reptrack-worker="$IMAGE:$TAG" -n reptrack
fi

kubectl rollout status deployment/reptrack-api -n reptrack --timeout=180s
if [ -n "$WORKER_YAML" ]; then
    kubectl rollout status deployment/reptrack-worker -n reptrack --timeout=180s
fi

echo "Production deploy of $TAG complete!"