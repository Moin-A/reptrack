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

DEPLOY_YAML=$(find . -regex ".*kube.*deployment.*\.yaml" | head -n 1)
WORKER_YAML=$(find . -regex ".*kube.*worker.*\.yaml" | head -n 1)
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

if [ -z "$DEPLOY_YAML" ]; then
    echo "❌ ERROR: Deployment manifest not found!"
    exit 1
fi

# Step 6: Kubernetes apply
echo "--- Applying Manifests ---"
kubectl apply -f "$DEPLOY_YAML"
if [ -n "$WORKER_YAML" ]; then     
   sudo kubectl apply -f "$WORKER_YAML"
fi

# Step 7: Database migration

echo "--- Ensuring cert-manager ---"
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.16.2/cert-manager.yaml
kubectl wait --for=condition=Available deployment/cert-manager -n cert-manager --timeout=120s
kubectl wait --for=condition=Available deployment/cert-manager-webhook -n cert-manager --timeout=120s

# --- 2. Create/update Cloudflare secret (value from GitHub Secrets, never in git) ---
echo "--- Syncing Cloudflare API token secret ---"
kubectl create secret generic cloudflare-api-token \
  --from-literal=api-token="$CLOUDFLARE_API_TOKEN" \
  -n cert-manager \
  --dry-run=client -o yaml | kubectl apply -f -

# --- 3. Apply our own manifests, explicitly, in order ---
