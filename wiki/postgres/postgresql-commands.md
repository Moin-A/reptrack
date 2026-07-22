# PostgreSQL Commands

**Summary:** Core PostgreSQL commands and concepts — connecting with `psql`, meta-commands, roles, config files, network access, and backup/restore.

**Tags:** postgres, postgresql, psql, database, sql

**Last updated:** 2026-07-22

---

## Connecting with `psql`

```bash
psql                                  # connect as current OS user to default db
psql -U postgres                      # connect as the postgres role
psql -U app_user -d reptrack -h host  # user, database, host
psql "postgresql://user:pass@host:5432/reptrack"   # connection URL
sudo -u postgres psql                 # connect as the postgres OS/role via peer auth
```

| Flag | Meaning |
|------|---------|
| `-U` | role (user) to connect as |
| `-d` | database name |
| `-h` | host (omit for local socket) |
| `-p` | port (default `5432`) |
| `-c "SQL"` | run one SQL statement and exit |

---

## Meta-commands (inside `psql`)

Meta-commands start with a backslash and are handled by `psql`, not the server.

```
\l                # list databases
\c dbname         # connect to / switch database
\dt               # list tables
\d table_name     # describe a table (columns, indexes, constraints)
\du               # list roles (users)
\dn               # list schemas
\df               # list functions
\x                # toggle expanded (row-per-line) output
\timing           # toggle query timing
\conninfo         # show current connection details
\q                # quit
```

---

## Roles & Databases

```sql
CREATE ROLE app_user WITH LOGIN PASSWORD 'secret';
CREATE DATABASE reptrack OWNER app_user;
GRANT ALL PRIVILEGES ON DATABASE reptrack TO app_user;
ALTER ROLE app_user WITH PASSWORD 'newsecret';
```

- A **role** is a user or a group; `LOGIN` makes it usable as a login account.
- Every database has an **owner** role with full control over it.

---

## Config Files

Two files govern how the server behaves and who may connect:

| File | Controls | Key setting |
|------|----------|-------------|
| `postgresql.conf` | server behavior — listen addresses, memory, connections, logging | `listen_addresses` |
| `pg_hba.conf` | host-based auth — *who* may connect, from where, and how | connection rules |

Find their locations from inside `psql`:

```sql
SHOW config_file;    -- path to postgresql.conf
SHOW hba_file;       -- path to pg_hba.conf
SHOW data_directory; -- path to the data dir
```

### Opening Postgres to the private network

`listen_addresses` governs **which network interfaces** Postgres accepts connections on:

- `localhost` (default) → only the same machine can connect
- `*` → listens on all interfaces, so other machines (e.g. an app EC2 instance) can reach it over the private network

```bash
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" postgresql.conf
```

See [[bash-commands]] for the `sed` breakdown.

Then add a rule in `pg_hba.conf` to allow the app subnet (CIDR + auth method):

```
# TYPE  DATABASE  USER      ADDRESS         METHOD
host    reptrack  app_user  10.0.0.0/16     scram-sha-256
```

> `listen_addresses` decides *where* Postgres listens; `pg_hba.conf` decides *who* among those connections may actually log in. Apply both with a restart.

### Applying config changes

```bash
sudo systemctl restart postgresql   # required for listen_addresses
sudo systemctl reload postgresql    # enough for most pg_hba.conf changes
```

```sql
SELECT pg_reload_conf();            -- reload config from within a session
```

---

## Backup & Restore

```bash
pg_dump -U app_user reptrack > reptrack.sql          # plain SQL dump
pg_dump -U app_user -Fc reptrack > reptrack.dump     # custom format (compressed)
psql -U app_user reptrack < reptrack.sql             # restore a plain dump
pg_restore -U app_user -d reptrack reptrack.dump     # restore a custom dump
pg_dumpall -U postgres > all.sql                     # all databases + roles
```

| Tool | Use |
|------|-----|
| `pg_dump` | dump a single database |
| `pg_dumpall` | dump the whole cluster (all DBs + global roles) |
| `pg_restore` | restore a custom/`-Fc` format dump |

### Dumping from a Kubernetes pod

When Postgres runs as a pod (no `psql`/`pg_dump` on the host), run the dump *inside* the container via `kubectl exec` and redirect the output to a file on your local machine.

```bash
sudo kubectl exec -n reptrack deploy/postgres -- pg_dump -U reptrack reptrack_production > reptrack_dump.sql
```

| Part | Meaning |
|------|---------|
| `kubectl exec` | run a command inside a pod |
| `-n reptrack` | namespace the pod lives in |
| `deploy/postgres` | target — `type/name` (the `postgres` Deployment) |
| `--` | end of kubectl flags; everything after runs in the container |
| `pg_dump` | the dump command (runs inside the pod) |
| `-U reptrack` | connect as the `reptrack` role |
| `reptrack_production` | database to dump |
| `> reptrack_dump.sql` | redirect stdout to a local file (runs on your host, not the pod) |

> The redirect `>` happens on your shell, so the `.sql` file lands on your **local** machine even though `pg_dump` runs inside the pod. `-U reptrack` and `-U postgres` are both valid — pick the role that owns / can read the database.

See [[bash-commands]] for redirects, and [[expose-pod]] / [[kubernetes]] for pod targeting.

---

## Service Management

```bash
sudo systemctl status postgresql    # check status
sudo systemctl start postgresql     # start
sudo systemctl restart postgresql   # restart (applies postgresql.conf changes)
sudo -u postgres pg_isready         # is the server accepting connections?
```

---

## See Also
- [[bash-commands]] — `sed` in-place editing used to change `listen_addresses`
