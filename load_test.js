import http from "k6/http";
import { check, group, sleep } from "k6";
import { Trend, Rate } from "k6/metrics";

// ---------------------------------------------------------------------------
// Config — override via k6 env vars:
//   k6 run -e BASE_URL=http://localhost:3000 -e USER_EMAIL=test@example.com ...
// ---------------------------------------------------------------------------
const BASE_URL = __ENV.BASE_URL || "http://localhost:3000";
const USER_EMAIL = __ENV.USER_EMAIL || "test@example.com";
const USER_PASSWORD = __ENV.USER_PASSWORD || "password123";

// ---------------------------------------------------------------------------
// Custom metrics
// ---------------------------------------------------------------------------
const loginDuration = new Trend("login_duration", true);
const tasksIndexDuration = new Trend("tasks_index_duration", true);
const taskCreateDuration = new Trend("task_create_duration", true);
const errorRate = new Rate("error_rate");

// ---------------------------------------------------------------------------
// Load profile
// ---------------------------------------------------------------------------
export const options = {
  scenarios: {
    // Ramp up to 20 VUs over 30s, hold for 1m, ramp down
    ramp_up: {
      executor: "ramping-vus",
      startVUs: 1,
      stages: [
        { duration: "30s", target: 20 },
        { duration: "1m", target: 20 },
        { duration: "15s", target: 0 },
      ],
    },
  },
  thresholds: {
    http_req_duration: ["p(95)<500", "p(99)<1000"], // 95th percentile < 500ms
    http_req_failed: ["rate<0.01"],                  // error rate < 1%
    error_rate: ["rate<0.01"],
  },
};

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
const jsonHeaders = {
  "Content-Type": "application/json",
  Accept: "application/json",
};

function login() {
  const res = http.post(
    `${BASE_URL}/users/sign_in`,
    JSON.stringify({ user: { email: USER_EMAIL, password: USER_PASSWORD } }),
    { headers: jsonHeaders }
  );

  loginDuration.add(res.timings.duration);

  const ok = check(res, {
    "login: status 200": (r) => r.status === 200,
    "login: got user id": (r) => {
      try {
        return JSON.parse(r.body).user?.id !== undefined;
      } catch {
        return false;
      }
    },
  });

  errorRate.add(!ok);
  return ok;
}

// ---------------------------------------------------------------------------
// Main VU function
// ---------------------------------------------------------------------------
export default function () {
  // Each VU logs in at the start of its iteration; the cookie jar is scoped
  // per-VU so the session persists for the whole iteration automatically.
  const loggedIn = login();
  if (!loggedIn) {
    sleep(1);
    return;
  }

  // --- Tasks ---
  group("tasks", () => {
    // List tasks
    const listRes = http.get(`${BASE_URL}/tasks`, { headers: jsonHeaders });
    tasksIndexDuration.add(listRes.timings.duration);
    const listOk = check(listRes, {
      "tasks index: status 200": (r) => r.status === 200,
    });
    errorRate.add(!listOk);

    sleep(0.5);

    // Create a task
    const taskPayload = JSON.stringify({
      task: {
        name: `Load test task ${Date.now()}`,
        description: "Created by k6 load test",
        status: "todo",
        bucket: "general",
      },
    });
    const createRes = http.post(`${BASE_URL}/tasks`, taskPayload, {
      headers: jsonHeaders,
    });
    taskCreateDuration.add(createRes.timings.duration);
    const createOk = check(createRes, {
      "task create: status 201": (r) => r.status === 201,
    });
    errorRate.add(!createOk);

    // If creation succeeded, fetch + delete the created task
    if (createOk) {
      let taskId;
      try {
        taskId = JSON.parse(createRes.body).id;
      } catch {}

      if (taskId) {
        sleep(0.3);

        const showRes = http.get(`${BASE_URL}/tasks/${taskId}`, {
          headers: jsonHeaders,
        });
        check(showRes, { "task show: status 200": (r) => r.status === 200 });

        sleep(0.3);

        const delRes = http.del(`${BASE_URL}/tasks/${taskId}`, null, {
          headers: jsonHeaders,
        });
        check(delRes, {
          "task delete: status 204 or 200": (r) =>
            r.status === 204 || r.status === 200,
        });
      }
    }
  });

  sleep(0.5);

  // --- Health check ---
  group("health", () => {
    const res = http.get(`${BASE_URL}/up`);
    check(res, { "health: status 200": (r) => r.status === 200 });
  });

  // --- Activities ---
  group("activities", () => {
    const res = http.get(`${BASE_URL}/activities`, { headers: jsonHeaders });
    check(res, { "activities index: status 200": (r) => r.status === 200 });
  });

  sleep(1);
}
