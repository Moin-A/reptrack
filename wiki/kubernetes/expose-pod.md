# kubectl expose pod

**Summary:** Expose a pod as a Kubernetes Service so it can be accessed via a port.

**Tags:** kubectl, pod, service, nodeport, networking, expose

**Last updated:** 2026-04-08

---

## Command

```bash
kubectl expose pod <pod-name> \
  --type=NodePort \
  --port=80 \
  --target-port=80 \
  -n reptrack
```

## Options

| Option | Description |
|--------|-------------|
| `<pod-name>` | Name of the pod to expose |
| `--type=NodePort` | Service type. `NodePort` makes the pod accessible on a static port on every node's IP (external access). Other types: `ClusterIP` (internal only), `LoadBalancer` (cloud load balancer) |
| `--port=80` | The port the **Service** listens on (what clients connect to) |
| `--target-port=80` | The port on the **pod/container** that traffic is forwarded to (must match the port your app listens on inside the container) |
| `-n reptrack` | Namespace to create the Service in. Must match the namespace the pod is running in |

## What It Does

Creates a `Service` resource that routes traffic to the specified pod. With `NodePort`, Kubernetes assigns a random high port (default range: 30000–32767) on the node. You can then access the pod at `<node-ip>:<node-port>`.

## Check the Assigned NodePort

```bash
kubectl get svc <pod-name> -n reptrack
```

Look for the `PORT(S)` column — it will show something like `80:31234/TCP`, where `31234` is the NodePort.

## See Also
- [[kubernetes]]
