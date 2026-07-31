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
docker build --network=host -t "$IMAGE:$TAG" .
docker push "$IMAGE:$TAG"


# Local k3s config — this runs ON EC2
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

#Create/update Cloudflare secret (value from GitHub Secrets, never in git) ---
echo "--- Syncing Cloudflare API token secret ---"
kubectl create secret generic cloudflare-api-token \
    --from-literal=api-token="$CLOUDFLARE_API_TOKEN" \
    -n cert-manager \
    --dry-run=client -o yaml | kubectl apply -f -

# Apply manifests — creates resources first run, updates structure after
echo "--- Applying Manifests ---"
kubectl apply -f production-kube-deployment.yaml
kubectl apply -f production-kube-worker.yaml
kubectl apply -f reptrack-api-prod-deployment.yaml


# Force rollout with the immutable SHA tag
echo "--- Deploying $TAG ---"
kubectl set image deployment/reptrack-api reptrack-api="$IMAGE:$TAG" -n reptrack
kubectl set image deployment/reptrack-worker reptrack-worker="$IMAGE:$TAG" -n reptrack


kubectl rollout status deployment/reptrack-api -n reptrack --timeout=180s
kubectl rollout status deployment/reptrack-worker -n reptrack --timeout=180s


if ! kubectl get deployment cert-manager -n cert-manager &>/dev/null; then
    echo "--- Ensuring cert-manager ---"
    kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.16.2/cert-manager.yaml
    kubectl wait --for=condition=Available deployment/cert-manager -n cert-manager --timeout=120s
    kubectl wait --for=condition=Available deployment/cert-manager-webhook -n cert-manager --timeout=120s
else
    echo "--- cert-manager already installed, skipping ---"
fi



echo "Production deploy of $TAG complete!"