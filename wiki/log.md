# Wiki Log

Append-only record of all ingestions, queries, and updates.

---

## 2026-07-22 — update
- Source: user command — kubectl exec pg_dump for reptrack_production
- Pages affected: `postgres/postgresql-commands.md`
- Notes: Added "Dumping from a Kubernetes pod" subsection — `kubectl exec -n reptrack deploy/postgres -- pg_dump ... > file.sql` with a part-by-part breakdown and the note that the redirect writes the dump to the local host.

---

## 2026-07-22 — create
- Source: user request — Postgres commands page
- Pages created: `postgres/postgresql-commands.md`
- Pages affected: `index.md`
- Notes: New `postgres/` topic folder and page covering psql connection/flags, meta-commands, roles & databases, postgresql.conf vs pg_hba.conf (listen_addresses, private-network access), applying config changes, pg_dump/pg_restore backups, and service management. Cross-links to bash-commands for the sed edit.

---

## 2026-07-22 — update
- Source: user-provided sed / postgresql.conf explanation
- Pages affected: `bash/bash-commands.md`, `index.md`
- Notes: Added "Stream Editing with sed" section — `s/OLD/NEW/` breakdown, `-i` in-place flag, and a Postgres example using `sed` to flip `listen_addresses` from `localhost` to `*` (with pg_hba.conf / systemctl restart context).

---

## 2026-05-13 — create
- Source: conversation — session cookie security discussion
- Pages created: `security/session-cookies.md`
- Pages affected: `index.md`
- Notes: Covers cookie contents, encryption, HttpOnly behaviour, session hijacking vectors, and hardening recommendations for reptrack's Devise + Next.js setup.

---

## 2026-05-13 — create
- Source: live k6 stress test session
- Pages created: `load-testing/realtime-load-testing-case-study.md`
- Pages affected: `index.md`
- Notes: Documented audit_test.js results — login → create task → update task → verify audit versions flow. Breaking point ~114 VUs, 41% timeout rate, 100% check pass rate. Key findings: bcrypt/worker bottleneck, unbounded Audit::Version.all query, PaperTrail double writes.

---

## 2026-04-30 — update
- Source: conversation — ActiveRecord internals exploration
- Pages affected: `ruby/rails-core-ext-and-validations.md`, `index.md`
- Pages created: `ruby/has-one-association.md`
- Notes: Added `validates` internal argument processing (extract_options!, slice!, validator loop). Created new page covering `has_one` — method signature, argument processing, builder/reflection flow, class method lookup chain, scope lambda, and full options/dependent table.

---

## 2026-04-13 — update
- Source: user-provided reptrack.co.in tunnel walkthrough
- Pages affected: `cloudflare_tunnel_setup.md`
- Notes: Added real-world section for reptrack.co.in setup on Raspberry Pi k3s. Covers existing tunnel reuse, Traefik hostname routing, remote config override gotcha, DNS migration from GoDaddy to Cloudflare, and final verification.

---

## 2026-04-13 — create
- Source: user request
- Pages created: `cloudflare_tunnel_setup.md`
- Notes: New page covering Cloudflare Tunnel setup — install, auth, tunnel creation, config.yml, DNS routing, systemd service, Kubernetes deployment, and troubleshooting.

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
