# Load Testing Concepts

---

## What is a VU (Virtual User)?

A VU is a simulated user running your test script in a loop. Each VU:
- Has its own session (cookie jar, connection)
- Runs independently and concurrently with other VUs
- Keeps looping through the script until the test ends

Think of it like opening your app in 94 browser tabs simultaneously — each tab is one VU hammering the server at the same time.

---

## What is a Stage?

A stage controls how many VUs are active over a period of time. You chain stages to shape the load curve.

```
VUs
200 |                ████████████
100 |          █████
 50 |    ██████
 10 |████
  1 |█
    |___________________________> time
     20s  60s  100s 140s 170s 180s
```

| Stage | What it does |
|---|---|
| `0→10 in 20s` | Warm up — gentle ramp |
| `10→50 in 40s` | Build pressure |
| `50→100 in 40s` | Heavy load |
| `100→200 in 40s` | Push to find the wall |
| `hold 200 for 30s` | Confirm the breaking point |
| `200→0 in 10s` | Cool down |

---

## What does "chaining stages" mean?

Think of it like hiring staff for a store.

- Stage 1 ends at 10 VUs → Stage 2 starts at 10 and goes to 50
- Stage 2 ends at 50 VUs → Stage 3 starts at 50 and goes to 100
- And so on...

```
Stage 1    Stage 2        Stage 3        Stage 4
[1→10]  →  [10→50]   →   [50→100]  →   [100→200]
```

Without chaining, you'd have to restart from 0 each time, which would never reflect real traffic — real users don't all arrive and leave at the exact same moment.

---

## Why does the app survive until ~94 VUs if bcrypt blocks threads?

Because not every request hits bcrypt at the exact same millisecond. There's natural timing spread:

```
t=0ms  Thread 1 → bcrypt (takes ~100ms)
t=10ms Thread 2 → bcrypt (takes ~100ms)
t=20ms Thread 3 → bcrypt (takes ~100ms)
t=100ms Thread 1 finishes → picks up next request
```

At low VU counts, requests arrive slowly enough that threads finish bcrypt and free up before the queue grows. As VUs increase, requests arrive faster than threads can finish bcrypt:

```
10 VUs  → queue barely forms → fine
50 VUs  → small queue → latency climbs
94 VUs  → queue grows faster than it drains → timeouts start
200 VUs → queue explodes → total collapse
```

94 was just the point where the queue grew fast enough to hit the 10s timeout. The app was already struggling from ~50 VUs — it just hadn't fully collapsed yet.

---

## Is the queue a Sidekiq issue?

No. Sidekiq handles background jobs — it runs separately, picks up jobs from Redis, and processes them outside the request cycle. It never touches the Puma thread pool.

The bottleneck is purely:
```
HTTP request → Puma thread → bcrypt → response
```

| | Puma | Sidekiq |
|---|---|---|
| Handles | HTTP requests | Background jobs |
| Bottleneck | bcrypt in threads | Not involved |
| Fix | More workers | N/A here |

---

## Why do DB calls not block all threads?

DB calls are I/O — the thread sends the query and then waits for Postgres to respond. During that wait, Ruby releases the GVL and lets another thread run:

```
Thread 1 → sends query → waiting for Postgres... → GVL released → Thread 2 runs
Thread 2 → sends query → waiting for Postgres... → GVL released → Thread 3 runs
Thread 3 → sends query → waiting for Postgres... → GVL released → Thread 1 resumes
```

All 3 threads making DB calls simultaneously = fine, they overlap their waiting.

**Bcrypt is the opposite** — pure CPU work, no waiting:

```
Thread 1 → bcrypt hashing → holds GVL the entire time → Thread 2 blocked
                                                        → Thread 3 blocked
```

Thread 1 never releases the GVL because it's never waiting for anything external.

---

## Workers vs Threads — what's the difference?

Ruby has the **GVL (Global VM Lock)** — only one thread can run Ruby code at a time per process. So adding more threads helps with I/O (DB, network) but not with CPU-heavy work like bcrypt.

Workers are **separate processes** — they each have their own GVL. So 4 workers genuinely run 4 bcrypt operations in parallel on 4 different CPU cores simultaneously.

### Before (1 worker, 3 threads)
```
Puma (single process)
└── 3 threads  →  3 concurrent requests
```

### After (6 workers, 5 threads)
```
Puma (cluster mode)
├── Worker 1 → 5 threads
├── Worker 2 → 5 threads
├── Worker 3 → 5 threads
├── Worker 4 → 5 threads
├── Worker 5 → 5 threads
└── Worker 6 → 5 threads
               ─────────────
               30 concurrent requests
```

---

## What is `preload_app!`?

Loads the Rails app once in the master process, then forks workers from it. Workers inherit the already-loaded code — faster boot, less memory used via copy-on-write.

## What is `on_worker_boot`?

After forking, each worker must get its own DB connection — they can't share the parent's. This callback reconnects ActiveRecord in each worker.

---

## Results Summary

| Config | Breaking Point | Checks Passed | Error Rate |
|---|---|---|---|
| 1 worker, 3 threads | ~94 VUs | 8% | 91% |
| 6 workers, 5 threads | ~125 VUs | **100%** | **0%** |
