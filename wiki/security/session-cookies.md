# Session Cookies in Rails + Next.js

**Summary:** How Devise session cookies work in reptrack, what they contain, security properties, attack vectors, and hardening recommendations.

**Tags:** security, cookies, devise, session, authentication, rails, nextjs

**Last updated:** 2026-05-13

---

## What the Cookie Contains

When `sign_in(resource_name, resource)` is called in Devise, Rails writes a cookie called `_reptrack_session`. Inside it holds:

```json
{
  "session_id": "abc123...",
  "warden.user.user.key": [[3], "$2a$12$..."]
}
```

- **User ID** — identifies who is logged in
- **Password digest checksum** — a slice of the bcrypt hash. If the password changes, this checksum changes and all existing sessions are immediately invalidated
- **Session ID** — unique identifier for this session

---

## Is It Encrypted?

Yes. Rails encrypts and signs the cookie using `secret_key_base`. The raw value looks like:

```
BAh7CEkiD3Nlc3Npb25faWQGOgZFVEkiJTY4NGU...
```

This is Base64-encoded encrypted data. An attacker who obtains the raw cookie value **cannot**:
- Read what's inside it
- Modify it — Rails will reject tampered cookies (it's signed)
- Forge a new one — they don't have `secret_key_base`

---

## How the Frontend Uses It

reptrack uses a Next.js frontend that proxies requests to the Rails API. The cookie flows like this:

```
Login → Rails sets _reptrack_session cookie
Browser stores cookie (HttpOnly — JS cannot read it)
Every request → browser forwards cookie to Next.js → Next.js forwards to Rails
Rails decrypts cookie → identifies user → responds
```

The frontend never reads the cookie directly. Instead it calls `GET /users/sessions/me` which asks Rails to identify the cookie holder and returns `{ id, email }`.

For server-side rendering, `getServerUser()` forwards the raw cookie header using Next.js's `cookies()` store.

---

## Can a Hacker Steal It?

**Encryption does not protect against session hijacking.** The attacker doesn't need to read the cookie — they just copy and paste the entire encrypted string into their browser. Rails only checks:

1. Is the signature valid? ✓ (they copied the whole thing)
2. Is it expired? ✓ (if no expiry is set)

It does **not** check who is presenting the cookie.

### Attack Vectors

| Attack | How |
|---|---|
| **XSS** | Inject malicious JS that reads `document.cookie` and exfiltrates it |
| **Man in the middle** | Intercept HTTP traffic on unsecured network (no HTTPS) |
| **Physical access** | Copy cookie from DevTools → Application → Cookies |

---

## Security Flags

| Flag | What it does | Status |
|---|---|---|
| `HttpOnly` | Blocks JS from reading the cookie — protects against XSS | ✓ Rails default |
| `Secure` | Cookie only sent over HTTPS — prevents MITM | ⚠️ production only if HTTPS configured |
| `SameSite: Lax` | Blocks cross-site request forgery | ✓ Rails default |
| Encrypted + Signed | Cannot be forged or tampered | ✓ |

### Can you see it in DevTools?

Yes — `HttpOnly` only blocks JavaScript. DevTools is a browser tool with direct cookie store access. You can always see and copy it from:

```
DevTools → Application → Cookies → your domain
```

---

## Hardening Recommendations

### 1. Session Expiry (Devise timeout)

```ruby
# config/initializers/devise.rb
config.timeout_in = 30.minutes  # expires after 30 min of inactivity
```

Sliding expiration — every request resets the timer. Stolen cookies are only valid within the inactivity window.

| App type | Recommended timeout |
|---|---|
| Banking | 5–10 minutes |
| SaaS / productivity | 30–60 minutes |
| Social / consumer | 7–30 days |

### 2. Secure Session Store Config

```ruby
# config/initializers/session_store.rb
Rails.application.config.session_store :cookie_store,
  key: "_reptrack_session",
  secure: Rails.env.production?,
  httponly: true,
  expire_after: 24.hours,
  same_site: :strict
```

### 3. Consider JWT for API-first apps

Devise's cookie session is designed for browser apps. For a proper API + frontend separation, short-lived JWTs with refresh tokens give more control:
- Short expiry (15 min) limits the stolen token window
- Refresh tokens can be revoked server-side
- `devise-jwt` is already installed in reptrack but not yet wired up

---

## See Also

- [[realtime-load-testing-case-study]] — performance context for the login endpoint
