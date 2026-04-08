# Bash Commands

**Summary:** Core bash commands and patterns for scripting, file management, SSH, and unix system concepts.

**Tags:** bash, shell, scripting, linux, unix

**Last updated:** 2026-04-08

---

## Variables & Environment

```bash
export MY_VAR="value"         # set env variable
echo $MY_VAR                  # print variable
printenv                      # print all env variables
unset MY_VAR                  # remove variable
MY_VAR=$(some command)        # capture command output into variable
```

---

## File Operations

```bash
ls / ls -la                   # list files / with details
pwd                           # current directory
cd /path/to/dir               # change directory
mkdir -p a/b/c                # create nested directories
rm file.txt / rm -rf folder   # delete file / folder
cp file.txt /dest/            # copy file
mv file.txt /dest/            # move or rename
cat file.txt                  # print file contents
```

---

## Searching & Finding Files

```bash
grep "pattern" file.txt           # search inside file
find . -name "*.sh"               # find by glob name
find . -name "*deployment*"       # find by partial name
find . -regex ".*kube.*deployment.*\.yaml"  # find by regex
which command                     # locate a command
```

### Glob vs Regex in `find`

| Pattern | Type | Meaning |
|---------|------|---------|
| `*deployment*` | glob (`-name`) | anything containing "deployment" |
| `.*deployment.*\.yaml` | regex (`-regex`) | same but full regex syntax |
| `.` | regex | any single character |
| `.*` | regex | zero or more characters |
| `\.` | regex | literal dot |

> On macOS, `find -regex` uses BRE — alternation (`\|`) may not work. Use two separate `find` calls or `-name` glob patterns instead.

### Saving find result to variable

```bash
DEPLOY_YAML=$(find . -regex ".*kube.*deployment.*\.yaml" | head -n 1)
# head -n 1 — take only first match
```

---

## Permissions

```bash
chmod +x script.sh            # make executable
chmod 600 file                # owner read/write only (e.g. SSH private keys)
chown user:group file         # change owner
```

### chmod 600 breakdown
```
6 = read + write (owner)
0 = no permissions (group)
0 = no permissions (others)
```
SSH refuses to use a private key unless it has 600 permissions.

---

## Networking & SSH

```bash
ssh user@host                                  # SSH into server
ssh -i /tmp/key -o StrictHostKeyChecking=no user@host "command"
scp file.txt user@host:~/                      # copy file to server
curl http://example.com                        # HTTP request
ping google.com                                # check connectivity
```

| SSH Flag | Meaning |
|----------|---------|
| `-i /path/key` | use this private key file |
| `-o StrictHostKeyChecking=no` | skip host fingerprint prompt (safe for automation) |
| `"command"` | run command on remote after connecting |

---

## Process Management

```bash
ps aux                        # list all running processes
kill PID                      # kill process by ID
killall process_name          # kill by name
```

---

## Conditionals

```bash
if [ "$VAR" == "value" ]; then
  echo "match"
fi
```

### Common flags

| Flag | Meaning |
|------|---------|
| `-z` | string is empty |
| `-n` | string is non-empty |
| `-f` | file exists |
| `-d` | directory exists |

```bash
if [ -z "$DEPLOY_YAML" ]; then
  echo "❌ ERROR: manifest not found"
  exit 1
fi
```

---

## Loops

```bash
for i in 1 2 3; do
  echo $i
done

while [ condition ]; do
  echo "running"
done
```

---

## Redirects

```bash
echo "text" > file.txt        # write (overwrite)
echo "text" >> file.txt       # append
command 2>&1                  # redirect stderr to stdout
```

---

## Users & Groups

Unix controls access via users and groups. Every file has three permission layers: owner, group, everyone else.

```bash
sudo usermod -aG docker rpi02   # add user to docker group
# -a = append (keep existing groups)
# -G = group(s) to add
```

Docker reuses this model: the daemon socket is owned by `root:docker` — you need to be in the `docker` group to use it without sudo.

---

## See Also
- [[kubernetes]] *(coming soon)*
