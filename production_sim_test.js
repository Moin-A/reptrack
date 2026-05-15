import http from "k6/http";
import { check, sleep } from "k6";
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

// ---------------------------------------------------------------------------
// Constant arrival rate — fires 100 iterations/s (1 every 10ms)
// Runs for 1 minute to simulate steady production traffic
// ---------------------------------------------------------------------------
export const options = {
  scenarios: {
    production_sim: {
      executor: "constant-arrival-rate",
      rate: 100,               // 100 iterations per second
      timeUnit: "1s",          // = 1 request every 10ms
      duration: "1m",
      preAllocatedVUs: 50,     // VUs ready to go immediately
      maxVUs: 200,             // k6 can spin up more if needed
    },
  },
  thresholds: {
    http_req_duration: ["p(95)<2000"],  // 95th percentile under 2s
    http_req_failed:   ["rate<0.05"],   // error rate under 5%
    error_rate:        ["rate<0.05"],
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
  if (!loginOk) return;

  // Step 2 — Create a task
  const createRes = http.post(
    `${BASE_URL}/tasks`,
    JSON.stringify({
      task: {
        name: `Prod sim task ${__VU}-${Date.now()}`,
        description: "k6 production simulation",
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
  if (!taskId) return;

  // Step 3 — Update the task
  const updateRes = http.put(
    `${BASE_URL}/tasks/${taskId}`,
    JSON.stringify({
      task: {
        name: `Prod sim task ${__VU}-${Date.now()} [updated]`,
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

  // Step 4 — Check activities (audit versions)
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

  // Step 5 — Clean up
  if (taskId) {
    const delRes = http.del(`${BASE_URL}/tasks/${taskId}`, null, { headers, timeout: "10s" });
    if (delRes.error_code !== 1050) {
      check(delRes, {
        "task delete 200 or 204": (r) => r.status === 200 || r.status === 204,
      });
    }
  }
}
