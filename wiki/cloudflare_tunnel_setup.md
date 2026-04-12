# Cloudflare Tunnel Setup

**Summary:** How to create and configure a Cloudflare Tunnel to expose local or Kubernetes services to the internet without opening firewall ports.

**Tags:** cloudflare, tunnel, networking, ingress, dns, reptrack, kubernetes, traefik

**Last updated:** 2026-04-13

---

## Overview

Cloudflare Tunnel (formerly Argo Tunnel) creates an outbound-only connection from your server to Cloudflare's edge. Traffic flows:

```
User → Cloudflare Edge → cloudflared daemon → Local Service
```

No inbound firewall rules or public IP required.

---

## Prerequisites

- A domain added to Cloudflare (with DNS managed by Cloudflare)
- A Cloudflare account (free tier works)
- `cloudflared` CLI installed

---

## Install cloudflared

```bash
# macOS
brew install cloudflare/cloudflare/cloudflared

# Linux (Debian/Ubuntu)
curl -L https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main" \
  | sudo tee /etc/apt/sources.list.d/cloudflared.list
sudo apt update && sudo apt install cloudflared

# Verify
cloudflared --version
```

---

## Authenticate

```bash
cloudflared tunnel login
```

This opens a browser to authorize your Cloudflare account. A certificate is saved to `~/.cloudflared/cert.pem`.

---

## Create a Tunnel

```bash
cloudflared tunnel create <tunnel-name>
```

This creates a tunnel and saves credentials to `~/.cloudflared/<tunnel-id>.json`.

List tunnels:
```bash
cloudflared tunnel list
```

---

## Configure the Tunnel

Create a config file at `~/.cloudflared/config.yml`:

```yaml
tunnel: <tunnel-id>
credentials-file: /root/.cloudflared/<tunnel-id>.json

ingress:
  - hostname: app.example.com
    service: http://localhost:3000
  - hostname: api.example.com
    service: http://localhost:8080
  - service: http_status:404   # catch-all rule (required)
```

- `hostname` — the public domain/subdomain to expose
- `service` — the local address to forward traffic to

---

## Create DNS Records

Route the hostname to the tunnel (Cloudflare manages the CNAME automatically):

```bash
cloudflared tunnel route dns <tunnel-name> app.example.com
cloudflared tunnel route dns <tunnel-name> api.example.com
```

This creates a CNAME in your Cloudflare DNS pointing to `<tunnel-id>.cfargotunnel.com`.

---

## Run the Tunnel

```bash
# Foreground (testing)
cloudflared tunnel run <tunnel-name>

# Background with config file
cloudflared tunnel --config ~/.cloudflared/config.yml run
```

---

## Run as a System Service

```bash
# Install as systemd service
sudo cloudflared service install

# Start / stop / status
sudo systemctl start cloudflared
sudo systemctl stop cloudflared
sudo systemctl status cloudflared

# Enable on boot
sudo systemctl enable cloudflared
```

---

## Deploy in Kubernetes

Use the official `cloudflare/cloudflared` Docker image as a Deployment.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cloudflared
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cloudflared
  template:
    metadata:
      labels:
        app: cloudflared
    spec:
      containers:
        - name: cloudflared
          image: cloudflare/cloudflared:latest
          args:
            - tunnel
            - --config
            - /etc/cloudflared/config.yml
            - run
          volumeMounts:
            - name: config
              mountPath: /etc/cloudflared
              readOnly: true
            - name: creds
              mountPath: /etc/cloudflared/creds
              readOnly: true
      volumes:
        - name: config
          configMap:
            name: cloudflared-config
        - name: creds
          secret:
            secretName: cloudflared-creds
```

Store the tunnel credentials JSON as a Secret:

```bash
kubectl create secret generic cloudflared-creds \
  --from-file=credentials.json=/root/.cloudflared/<tunnel-id>.json
```

Store `config.yml` as a ConfigMap:

```bash
kubectl create configmap cloudflared-config \
  --from-file=config.yml=/root/.cloudflared/config.yml
```

---

## Useful Commands

| Command | Description |
|---------|-------------|
| `cloudflared tunnel list` | List all tunnels |
| `cloudflared tunnel info <name>` | Show tunnel details and connections |
| `cloudflared tunnel delete <name>` | Delete a tunnel |
| `cloudflared tunnel route dns <name> <hostname>` | Add DNS route |
| `cloudflared tunnel cleanup <name>` | Remove inactive connections |

---

## Troubleshooting

- **DNS not resolving** — confirm the CNAME exists in Cloudflare DNS dashboard; allow a few minutes for propagation.
- **Tunnel not connecting** — check `cloudflared` logs with `journalctl -u cloudflared -f` or run in foreground to see output.
- **502 Bad Gateway** — the local `service` address in `config.yml` is unreachable; confirm the service is running on that port.
- **Certificate error** — re-run `cloudflared tunnel login` to refresh `cert.pem`.

---

## Real-World Example: reptrack.co.in on Raspberry Pi k3s

This documents the actual setup used to expose `reptrack-service` (Rails app in a k3s cluster on a Raspberry Pi) via the same tunnel already serving `practify.co.in`.

### Existing tunnel

```
Tunnel name:  practify-rpi
Tunnel ID:    23645243-3f27-4ad2-8199-24db5b2d55d2
Credentials:  /etc/cloudflared/23645243-3f27-4ad2-8199-24db5b2d55d2.json
Config:       /etc/cloudflared/config.yml
cloudflared:  /usr/local/bin/cloudflared (systemd service)
```

> `sudo cloudflared tunnel list` fails on this machine — no `cert.pem` present. The tunnel uses `credentials-file` auth only. Use `cloudflared tunnel list` (without sudo) or check the dashboard instead.

### Routing architecture

Both `practify.co.in` and `reptrack.co.in` route to the same IP and port:

```
cloudflared → http://192.168.29.28:80 → Traefik (k3s ingress)
                                              ├── Host: practify.co.in  → practify-service
                                              └── Host: reptrack.co.in  → reptrack-service
```

Traefik does hostname-based routing — multiple services share port 80. Accessing `192.168.29.28:80` directly by IP returns 404 (no matching Host header), but cloudflared sends `Host: reptrack.co.in` so Traefik routes correctly.

### reptrack-service details

```
Namespace:  reptrack
Service:    reptrack-service  (ClusterIP :80, NodePort 30875)
Pod:        reptrack-6d5bf65868-zsndg
Ingress:    reptrack-ingress → reptrack.co.in, www.reptrack.co.in → reptrack-service:80
```

> k3s API server is not reachable at `127.0.0.1:6443` on this machine. Use `--server=https://192.168.29.28:6443` for kubectl commands.

### Updated config.yml

```yaml
tunnel: 23645243-3f27-4ad2-8199-24db5b2d55d2
credentials-file: /etc/cloudflared/23645243-3f27-4ad2-8199-24db5b2d55d2.json

ingress:
  - hostname: practify.co.in
    service: http://192.168.29.28:80
  - hostname: www.practify.co.in
    service: http://192.168.29.28:80
  - hostname: reptrack.co.in
    service: http://192.168.29.28:80
  - hostname: www.reptrack.co.in
    service: http://192.168.29.28:80
  - service: http_status:404
```

After editing, restart the service:

```bash
sudo systemctl restart cloudflared
sudo systemctl status cloudflared
```

### Critical gotcha: remote config override

After restarting, logs showed:

```
INF Updated to new configuration config={"ingress":[{"hostname":"practify.co.in",
"service":"http://192.168.29.28"}, {"service":"http_status:404"}]} version=3
```

**Cloudflare's control plane pushes a remote config that overrides `config.yml`.** The local file is ignored when the tunnel is remotely managed. The dashboard is the source of truth.

Fix: Go to **Cloudflare Dashboard → Zero Trust → Networks → Tunnels → practify-rpi → Public Hostname → Add a public hostname** and add each route there.

### DNS setup for reptrack.co.in

`reptrack.co.in` was registered on GoDaddy and had to be moved to Cloudflare DNS:

1. Added `reptrack.co.in` as a new site in Cloudflare dashboard
2. Added a placeholder A record (`@ → 192.168.29.28`) to satisfy Cloudflare's activation check
3. Updated nameservers in GoDaddy:
   - Removed: `ns31.domaincontrol.com`, `ns32.domaincontrol.com`
   - Added: `bayan.ns.cloudflare.com`, `kristina.ns.cloudflare.com`
4. Deleted the placeholder A record once the domain was active
5. Added CNAME records (Proxied):
   - `@` → `23645243-3f27-4ad2-8199-24db5b2d55d2.cfargotunnel.com`
   - `www` → `23645243-3f27-4ad2-8199-24db5b2d55d2.cfargotunnel.com`

### Verification

```bash
curl -I https://reptrack.co.in
```

```
HTTP/2 404
x-request-id: d0db6322-c32e-414d-90f8-3d5fec6804b3
x-runtime: 0.002820
server: cloudflare
```

`x-request-id` and `x-runtime` are Rails headers — the request reached the app. The 404 is application-level (no root route defined in Rails), not a tunnel or infra issue. SSL works automatically via Cloudflare — no certificate installation needed on the server.

### Key learnings

| Learning | Detail |
|----------|--------|
| Traefik hostname routing | Port 80 handles multiple services via `Host` header — no separate ports needed |
| Remote config override | Cloudflare pushes tunnel config from the dashboard; `config.yml` is overridden |
| Dashboard is source of truth | Add routes in **Tunnels → Public Hostname**, not just `config.yml` |
| SSL is free and automatic | Cloudflare terminates TLS — no cert setup needed on the server |
| Placeholder A record | Required by Cloudflare to activate a new domain; delete it after adding the CNAME |
| k3s API server address | On this Pi, use `--server=https://192.168.29.28:6443`, not `127.0.0.1:6443` |

---

## See Also
- [[kubernetes]]
- [[expose-pod]]
