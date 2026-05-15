import http from "k6/http";
import { check, group, sleep } from "k6";
import { Trend, Rate, Counter } from "k6/metrics";

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------
const BASE_URL      = __ENV.BASE_URL      || "http://localhost:3000";
const USER_EMAIL    = __ENV.USER_EMAIL    || "test@example.com";
const USER_PASSWORD = __ENV.USER_PASSWORD || "password123";

// ---------------------------------------------------------------------------
// Custom metrics
// ---------------------------------------------------------------------------
const loginDuration      = new Trend("login_duration", true);
const createDuration     = new Trend("task_create_duration", true);
const updateDuration     = new Trend("task_update_duration", true);
const activitiesDuration = new Trend("activities_duration", true);
const errorRate          = new Rate("error_rate");
const timeouts           = new Counter("timeouts");
const auditMissCount     = new Counter("audit_versions_missing");

// ---------------------------------------------------------------------------
// Aggressive ramp — find the breaking point
// Stage 1:  0→10  VUs in 20s  (warm up)
// Stage 2: 10→50  VUs in 40s  (build pressure)
// Stage 3: 50→100 VUs in 40s  (heavy load)
// Stage 4: 100→200 VUs in 40s (find the wall)
// Stage 5: hold 200 for 30s   (confirm the wall)
// Stage 6: 200→0  VUs in 10s  (cool down)
// ---------------------------------------------------------------------------
export const options = {
  scenarios: {
    audit_stress: {
      executor: "ramping-vus",
      startVUs: 1,
      stages: [
        { duration: "20s", target: 10  },
        { duration: "40s", target: 50  },
        { duration: "40s", target: 100 },
        { duration: "40s", target: 200 },
        { duration: "30s", target: 200 },
        { duration: "10s", target: 0   },
      ],
      gracefulRampDown: "10s",
    },
  },
  // No hard thresholds — observe, don't fail early
  thresholds: {
    http_req_duration: ["p(95)<10000"],
    http_req_failed:   ["rate<1.0"],
  },
};

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
const headers = {
  "Content-Type": "application/json",
  Accept: "application/json",
};

// ---------------------------------------------------------------------------
// Main VU function
// ---------------------------------------------------------------------------
export default function () {
  // Step 1 — Login
  const loginRes = http.post(
    `${BASE_URL}/users/sign_in`,
    JSON.stringify({ user: { email: USER_EMAIL, password: USER_PASSWORD } }),
    { headers, timeout: "10s" }
  );

  if (loginRes.error_code === 1050) { timeouts.add(1); return; }

  loginDuration.add(loginRes.timings.duration);
  const loginOk = check(loginRes, {
    "login 200": (r) => r.status === 200,
  });
  errorRate.add(!loginOk);
  if (!loginOk) { sleep(0.5); return; }

  sleep(0.2);

  // Step 2 — Create a task
  const createRes = http.post(
    `${BASE_URL}/tasks`,
    JSON.stringify({
      task: {
        name: `Stress task ${__VU}-${Date.now()}`,
        description: "k6 audit stress test",
        status: "todo",
        bucket: "today",
      },
    }),
    { headers, timeout: "10s" }
  );

  if (createRes.error_code === 1050) { timeouts.add(1); return; }

  createDuration.add(createRes.timings.duration);
  const createOk = check(createRes, {
    "task create 201": (r) => r.status === 201,
  });
  errorRate.add(!createOk);

  let taskId;
  if (createOk) {
    try { taskId = JSON.parse(createRes.body).id; } catch {}
  }
  if (!taskId) { sleep(0.5); return; }

  sleep(0.2);

  // Step 3 — Update the task (triggers PaperTrail :update version)
  const updateRes = http.put(
    `${BASE_URL}/tasks/${taskId}`,
    JSON.stringify({
      task: {
        name: `Stress task ${__VU}-${Date.now()} [updated]`,
        status: "in_progress",
        bucket: "tomorrow",
      },
    }),
    { headers, timeout: "10s" }
  );

  if (updateRes.error_code === 1050) { timeouts.add(1); return; }

  updateDuration.add(updateRes.timings.duration);
  const updateOk = check(updateRes, {
    "task update 200": (r) => r.status === 200,
  });
  errorRate.add(!updateOk);

  sleep(0.2);

  // Step 4 — Hit /activities to verify audit versions are being written
  const actRes = http.get(`${BASE_URL}/activities`, { headers, timeout: "10s" });

  if (actRes.error_code === 1050) { timeouts.add(1); return; }

  activitiesDuration.add(actRes.timings.duration);
  const actOk = check(actRes, {
    "activities 200": (r) => r.status === 200,
    "activities has versions": (r) => {
      try {
        const body = JSON.parse(r.body);
        return Array.isArray(body.groups) && body.groups.length > 0;
      } catch { return false; }
    },
  });
  errorRate.add(!actOk);
  if (!actOk) auditMissCount.add(1);

  sleep(0.2);

  // Step 5 — Clean up
  const delRes = http.del(`${BASE_URL}/tasks/${taskId}`, null, { headers, timeout: "10s" });
  if (delRes.error_code === 1050) { timeouts.add(1); return; }
  check(delRes, {
    "task delete 200 or 204": (r) => r.status === 200 || r.status === 204,
  });

  sleep(0.1);
}
