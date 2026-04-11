# Wiki Log

Append-only record of all ingestions, queries, and updates.

---

## 2026-04-12 — update
- Source: user-provided Volumes and VolumeMounts primer
- Pages affected: `kubernetes/kubernetes.md`
- Notes: Added Volumes and VolumeMounts section covering volumes (source), volumeMounts (destination), how name links them, and why it enables environment-agnostic images.

---

## 2026-04-09 — update
- Source: user-provided Kubernetes Concepts Reference
- Pages affected: `kubernetes/kubernetes.md`, `index.md`
- Notes: Populated kubernetes.md with manifest anatomy, apiVersion/kind/metadata/annotations, spec/template/imagePullSecrets, env vs envFrom, Service, Ingress, Ingress Controller, Traefik Middleware, and Canary Deployments.

---

## 2026-04-08 — update
- Source: user command `kubectl expose pod`
- Pages created: `kubernetes/expose-pod.md`
- Notes: Added kubectl expose pod command with NodePort options explained. Covers --type, --port, --target-port, -n flags and how to check the assigned NodePort.

---

## 2026-04-08 — ingest
- Source: `sources/bash_commands.md`
- Pages created: `bash/bash-commands.md`
- Notes: Initial ingestion of bash reference. Covers environment variables, file ops, permissions, networking, process management, searching, conditionals, loops, redirects, SSH, and user/group concepts.
