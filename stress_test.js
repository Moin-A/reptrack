import http from "k6/http";
import { check, sleep } from "k6";
import { Trend, Rate, Counter } from "k6/metrics";

const BASE_URL = __ENV.BASE_URL || "http://localhost:3000";
const USER_EMAIL = __ENV.USER_EMAIL || "moin00dev@gmail.com";
const USER_PASSWORD = __ENV.USER_PASSWORD || "Thequint@101992";

// Custom metrics
const loginDuration    = new Trend("login_duration", true);
const tasksDuration    = new Trend("tasks_index_duration", true);
const activitiesDuration = new Trend("activities_index_duration", true);
const errorRate        = new Rate("error_rate");
const timeouts         = new Counter("timeouts");

// ---------------------------------------------------------------------------
// Aggressive ramp — find the breaking point
// Stage 1:  0→10 VUs in 20s  (warm up)
// Stage 2: 10→50 VUs in 40s  (build pressure)
// Stage 3: 50→100 VUs in 40s (heavy load)
// Stage 4: 100→200 VUs in 40s (find the wall)
// Stage 5: hold 200 VUs for 30s (confirm the wall)
// Stage 6: 200→0 VUs in 10s  (cool down)
// ---------------------------------------------------------------------------
export const options = {
  scenarios: {
    stress: {
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
  // No hard thresholds — we want to observe, not fail the run early
  thresholds: {
    http_req_duration:    ["p(95)<10000"], // just prevent k6 from erroring
    http_req_failed:      ["rate<1.0"],
  },
};

const headers = {
  "Content-Type": "application/json",
  Accept: "application/json",
};

export default function () {
  // Login
  const loginRes = http.post(
    `${BASE_URL}/users/sign_in`,
    JSON.stringify({ user: { email: USER_EMAIL, password: USER_PASSWORD } }),
    { headers, timeout: "10s" }
  );

  if (loginRes.error_code === 1050) { // connection timeout
    timeouts.add(1);
    return;
  }

  loginDuration.add(loginRes.timings.duration);
  const loginOk = check(loginRes, {
    "login 200": (r) => r.status === 200,
  });
  errorRate.add(!loginOk);

  if (!loginOk) {
    sleep(0.5);
    return;
  }

  sleep(0.2);

  // GET /tasks
  const tasksRes = http.get(`${BASE_URL}/tasks`, { headers, timeout: "10s" });
  if (tasksRes.error_code === 1050) { timeouts.add(1); return; }
  tasksDuration.add(tasksRes.timings.duration);
  const tasksOk = check(tasksRes, { "tasks 200": (r) => r.status === 200 });
  errorRate.add(!tasksOk);

  sleep(0.2);

  // GET /activities
  const actRes = http.get(`${BASE_URL}/activities`, { headers, timeout: "10s" });
  if (actRes.error_code === 1050) { timeouts.add(1); return; }
  activitiesDuration.add(actRes.timings.duration);
  const actOk = check(actRes, { "activities 200": (r) => r.status === 200 });
  errorRate.add(!actOk);

  sleep(0.1);
}
