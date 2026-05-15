# Realtime Load Testing Case Study

**Summary:** End-to-end k6 stress tests run against the reptrack Rails API — covering login, task create/update, audit version verification, and the performance findings from each run.

**Tags:** load-testing, k6, performance, puma, paper-trail, audit, bcrypt

**Last updated:** 2026-05-13 (Fix 1 added)

---

## Overview

This case study documents real k6 stress tests run against `http://localhost:3000`. Each test ramps from 1 VU to 200 VUs over 3 minutes using this stage profile:

```
Stage 1:  0 → 10  VUs in 20s  (warm up)
Stage 2: 10 → 50  VUs in 40s  (build pressure)
Stage 3: 50 → 100 VUs in 40s  (heavy load)
Stage 4: 100 → 200 VUs in 40s (find the wall)
Stage 5: hold 200 for 30s     (confirm the wall)
Stage 6: 200 → 0  VUs in 10s  (cool down)
```

---

## Test 1 — Login → Create Task → Update Task → Verify Audit Versions

**Script:** `audit_test.js`
**Config:** 1 Puma worker, 3 threads (reverted from optimised config)
**Date:** 2026-05-13

### What each VU does

1. `POST /users/sign_in` — authenticate
2. `POST /tasks` — create a task (triggers PaperTrail `:create` version)
3. `PUT /tasks/:id` — update the task (triggers PaperTrail `:update` version)
4. `GET /activities` — verify audit versions were recorded
5. `DELETE /tasks/:id` — clean up

### Results

| Metric | Value |
|---|---|
| Total iterations | 1,570 |
| Checks passed | **100%** (2,147 / 2,147) |
| Timeout rate | **41.24%** (1,360 / 3,297 requests) |
| p(95) http_req_duration | 10s (hitting timeout ceiling) |
| Breaking point | ~114 VUs |

### Per-operation latency

| Operation | avg | median | p(95) |
|---|---|---|---|
| Login (`POST /users/sign_in`) | 3.31s | 2.36s | 8.59s |
| Activities query (`GET /activities`) | 2.52s | 1.11s | 8.47s |
| Task create (`POST /tasks`) | 2.03s | 1.13s | 5.74s |
| Task update (`PUT /tasks/:id`) | 1.55s | 573ms | 5.91s |

### What passed

All checks that completed returned the correct response — no incorrect status codes, no missing audit versions. The `activities has versions` check passed on every successful request, confirming PaperTrail is recording both `:create` and `:update` events reliably under load.

### What failed

41% of requests timed out before completing. The server was not returning wrong answers — it was simply not fast enough to serve all concurrent requests within the 10s timeout.

---

## Findings and Optimization Opportunities

### 1. Bcrypt / Puma thread bottleneck (same as prior tests)

Login is the slowest operation (avg 3.31s, p(95) 8.59s). Bcrypt holds the GVL for the full hash duration, blocking all other threads in the same process. With 1 worker and 3 threads, the Puma queue saturates at ~114 VUs — consistent with the ~94 VU wall seen in previous stress tests.

**Fix:** More Puma workers (separate processes = separate GVLs = true parallelism for CPU-bound bcrypt).

### 2. `GET /activities` — unbounded full table scan

The activities endpoint runs `Audit::Version.all` with no limit or pagination. As tasks are created and updated during the test, the `versions` table grows continuously. Each subsequent `/activities` call scans more rows, so latency degrades over the run (avg 2.52s, p(95) 8.47s — nearly as slow as login).

**Fix:** Add pagination (e.g. `limit(50).order(created_at: :desc)`) or scope the query to the current user's versions. This is a DB query issue independent of the worker count — it will worsen as production data grows.

### 3. PaperTrail double DB writes under load

Every `POST /tasks` triggers a PaperTrail `:create` insert into `versions`. Every `PUT /tasks/:id` triggers a `:update` insert. Under high concurrency, these extra writes increase DB contention on top of the bcrypt bottleneck, compressing the thread pool further.

**Fix:** Not an immediate blocker, but consider async version writes via a background job (Sidekiq) for non-critical audit trails if DB write latency becomes a bottleneck at scale.

---

---

## Fix 1 — Added Eager Loading (`includes(:item)`)

**Change:** Added `.includes(:item)` to `Audit::Version.all` in `ActivitiesController#filtered_users`.

Bullet gem confirmed the N+1 after server restart:

```
USE eager loading detected
  Audit::Version => [:item]
  Add to your query: .includes([:item])
```

For every version record, the serializer was firing an individual `Task Load` query. With hundreds of versions in the table from load test runs, this added up to hundreds of DB roundtrips per `/activities` request.

### Before vs After (20 VUs, 30s run)

| Metric | Before `includes` | After `includes` | Improvement |
|---|---|---|---|
| `activities` avg | 6.11s | 3.24s | **47% faster** |
| `activities` p(95) | 9.34s | 5.89s | **37% faster** |
| Timeout rate | 11% (34 timeouts) | **0%** | **100% eliminated** |
| Checks passed | 100% | 100% | same |

**Still slow because:** the query fetches every version row ever written (`Audit::Version.all` with no limit). Next fix is pagination.

---

## See Also

- [[load-testing-concepts]] — VUs, stages, GVL, workers vs threads
