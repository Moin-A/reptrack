# Kubernetes Concepts Reference

**Summary:** Key Kubernetes manifest fields and concepts — manifest anatomy, networking, Traefik, and canary deployments.

**Tags:** kubernetes, manifest, yaml, deployment, configmap, service, ingress, traefik, canary

**Last updated:** 2026-04-09

---

## Manifest

A complete YAML block declaring a single Kubernetes resource. One file can contain multiple manifests separated by `---`. Each manifest has `apiVersion`, `kind`, `metadata`, and usually `spec`.

---

## apiVersion

Tells Kubernetes which API group and version the resource belongs to.

- `v1` — core resources (ConfigMap, Service, Pod)
- `apps/v1` — higher-level resources (Deployment)
- `networking.k8s.io/v1` — networking resources (Ingress)

Different resource types live in different API groups, hence different `apiVersion` values.

---

## kind

The type of Kubernetes resource being declared (e.g. `ConfigMap`, `Deployment`, `Service`, `Ingress`).

---

## metadata

Holds information about the resource — `name`, `namespace`, `labels`, and `annotations`.

---

## annotations

Key-value metadata attached to a resource as notes or signals for tools and controllers. They don't affect how the resource works directly — they're read by external tools to decide how to handle the resource.

- Format: `domain/key: value` (e.g. `kubernetes.io/ingress.class: traefik`)
- The domain prefix namespaces the annotation to avoid conflicts between different tools

---

## data (ConfigMap)

Stores key-value pairs in a ConfigMap. Each key is a name; the value is the content (e.g. a config file, a Ruby file, a string). Pods can access these values as environment variables or mounted files.

```yaml
data:
  gg_host.rb: |
    # Ruby file contents here
```

---

## spec

Defines the desired state of a resource — the specification of what you want Kubernetes to create or maintain. For a Deployment, it includes replicas, selector, and template.

---

## spec.template

The blueprint Kubernetes uses to create pods. Contains:
- `metadata` — labels for the pod
- `spec` — the pod-level spec (containers, volumes, etc.)

The inner `spec` (pod spec) is nested inside `template`, which is inside the outer `spec` (deployment spec).

---

## spec.template.spec.imagePullSecrets

References a Secret containing credentials for a private container registry. Kubernetes uses these credentials to authenticate and pull your image before starting the pod.

---

## env vs envFrom

Both inject environment variables into containers, but work differently:

| Field | Behaviour |
|-------|-----------|
| `envFrom` | Pulls **all** key-value pairs from a ConfigMap or Secret at once |
| `env` | Defines variables individually — can hardcode values or reference specific keys |

Within `env`, each entry uses either:
- `name` + `value` — hardcoded value directly in the manifest
- `name` + `valueFrom` — pulls value from a ConfigMap, Secret, or pod metadata

---

## Service

A stable network abstraction in front of your pods. Gives your app a consistent IP and DNS name, even as pods are replaced. Routes traffic to whichever pods match its selector.

---

## Ingress

A Kubernetes resource that declares routing rules for external traffic — which hostnames and paths route to which Services. By itself it does nothing; it needs an **ingress controller** to implement the rules.

Example rules:
- `practify.co.in/` → `practify-service:80`
- `api.practify.co.in/` → `api-service:3000`

---

## Ingress Controller

The actual software that reads Ingress manifests and implements the routing. Common options:

| Controller | Notes |
|------------|-------|
| **Traefik** | Kubernetes-native, easy setup, built-in Let's Encrypt |
| **NGINX** | Most popular, battle-tested, existed before Kubernetes |
| **HAProxy** | High performance, widely used |
| **Istio** | Full service mesh, more advanced use cases |
| Cloud-specific | AWS ALB, GCP GLBC, etc. |

**Ingress = the config. Controller = the thing doing the work.**

---

## Traefik Middleware

Middleware processes requests before they reach your backend service — like a bouncer that checks rules, enforces limits, and transforms requests.

| Middleware | What it does |
|------------|--------------|
| **Rate Limiting** | Limits requests from a single IP per second/minute |
| **Authentication** | Validates JWT tokens or basic auth before passing to your app |
| **Request Headers** | Adds, removes, or modifies HTTP headers |
| **Path Stripping** | Removes a URL prefix before routing to the backend |
| **Circuit Breaker** | Stops sending traffic to a failing service temporarily |
| **Compression** | Gzips responses to reduce bandwidth |
| **Retry** | Automatically retries failed requests |
| **CORS** | Handles cross-origin request headers |

> **Note:** Middleware at the Traefik level applies across all replicas globally. Rails' built-in rate limiting only protects a single instance.

---

## Canary Deployments (via Traefik weighted routing)

Run two versions of your app simultaneously and split traffic by percentage. Gradually increase traffic to the new version while monitoring for errors or latency spikes. Roll back instantly if something goes wrong.

```
v1 (stable) ← 95% of traffic
v2 (new)    ←  5% of traffic
```

Once v2 is stable, flip to 100%.

---

## Volumes and VolumeMounts

Kubernetes lets you inject files into containers at runtime without baking them into the Docker image — so you can use the same image across dev, staging, and production with different configs.

### volumes — The Source

Declares where the data comes from. Example using a ConfigMap:

```yaml
volumes:
  - name: hosts-config
    configMap:
      name: practify-hosts-config
```

This creates a volume called `hosts-config` that pulls its contents from the `practify-hosts-config` ConfigMap.

### volumeMounts — The Destination

Specifies where that data appears inside the container:

```yaml
volumeMounts:
  - name: hosts-config
    mountPath: /rails/config/initializers/zz_hosts.rb
    subPath: zz_hosts.rb
```

This mounts the `hosts-config` volume at the given path inside the container. `subPath` lets you mount a single key from the ConfigMap as a file rather than the whole volume as a directory.

### How They Connect

The `name` field is the link. Kubernetes matches the `volumeMounts[].name` to the `volumes[].name`. The ConfigMap has its own name (`practify-hosts-config`), but the volume reference name (`hosts-config`) is what connects the two sides.

### Why It Matters

You can change configuration without rebuilding the image. Deploy the same Docker image everywhere — just swap ConfigMaps per environment.

---

## See Also
- [[expose-pod]]
