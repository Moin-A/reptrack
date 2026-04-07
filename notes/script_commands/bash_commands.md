# Bash Commands Reference

## Print a value
```bash
echo "hello"
echo $MY_VAR
```

## Environment Variables
```bash
export MY_VAR="value"         # set variable
echo $MY_VAR                  # print variable
printenv                      # print all variables
unset MY_VAR                  # remove variable
```

## Associative Arrays (hash/object)
```bash
declare -A MY_HASH
MY_HASH["key"]="value"
echo ${MY_HASH["key"]}        # access value

for key in "${!MY_HASH[@]}"; do
  echo "$key = ${MY_HASH[$key]}"
done
```

## File Operations
```bash
ls                            # list files
ls -la                        # list with details
pwd                           # current directory
cd /path/to/dir               # change directory
mkdir my_folder               # create directory
mkdir -p a/b/c                # create nested directories
rm file.txt                   # delete file
rm -rf my_folder              # delete folder
cp file.txt /dest/            # copy file
mv file.txt /dest/            # move/rename file
cat file.txt                  # print file contents
```

## Permissions
```bash
chmod +x script.sh            # make executable
chmod 600 file                # owner read/write only
chown user:group file         # change owner
```

## Networking
```bash
ssh user@host                 # SSH into server
scp file.txt user@host:~/     # copy file to server
curl http://example.com       # make HTTP request
ping google.com               # check connectivity
```

## Process Management
```bash
ps aux                        # list running processes
kill PID                      # kill process by ID
killall process_name          # kill by name
```

## Searching
```bash
grep "pattern" file.txt       # search in file
find . -name "*.sh"           # find files by name
find . -name "*deployment*"   # find by partial name (glob)
find . -regex ".*deployment.*kube.*\.yaml"  # find using regex
which command                 # find command location
```

## Command Substitution — Saving Output to a Variable
`$()` captures the output of a command and stores it in a variable.

```bash
MY_VAR=$(some command)        # save output of command into variable
```

Without `$()` — just prints to terminal, nothing saved:
```bash
find . -name "*.yaml"
```

With `$()` — output is captured and stored:
```bash
DEPLOY_YAML=$(find . -name "*.yaml" | head -n 1)
echo $DEPLOY_YAML             # prints the file path
```

## Find a File and Save Path
```bash
# by exact name
DEPLOY_YAML=$(find . -name "practify-deployment.yaml" | head -n 1)

# by glob pattern (anything containing "deployment")
DEPLOY_YAML=$(find . -name "*deployment*.yaml" | head -n 1)

# by regex (must contain both "deployment" and "kube")
DEPLOY_YAML=$(find . -regex ".*deployment.*kube.*\.yaml" | head -n 1)
```

`head -n 1` — take only the first result in case multiple files match.

### Glob vs Regex
| Pattern | Type | Meaning |
|---------|------|---------|
| `*deployment*` | glob | anything containing "deployment" |
| `.*deployment.*\.yaml` | regex | same but with full regex syntax |
| `.` | regex | any single character |
| `.*` | regex | anything (zero or more characters) |
| `\.` | regex | literal dot (escaped) |

## Conditionals
```bash
if [ "$VAR" == "value" ]; then
  echo "match"
fi

if [ -f "file.txt" ]; then    # check file exists
  echo "exists"
fi

if [ -d "folder" ]; then      # check directory exists
  echo "exists"
fi

if [ -z "$VAR" ]; then        # check if variable is empty
  echo "VAR is empty"
  exit 1
fi

if [ -n "$VAR" ]; then        # check if variable is non-empty
  echo "VAR has a value"
fi
```

### Common [ ] flags
| Flag | Meaning |
|------|---------|
| `-z` | string is empty |
| `-n` | string is non-empty |
| `-f` | file exists |
| `-d` | directory exists |

## Loops
```bash
for i in 1 2 3; do
  echo $i
done

while [ condition ]; do
  echo "running"
done
```

## Redirects
```bash
echo "text" > file.txt        # write to file (overwrite)
echo "text" >> file.txt       # append to file instead of overwriting
command 2>&1                  # redirect stderr to stdout
```

## chmod 600 Explained
Sets strict permissions on a file so only the owner can read and write it.
SSH requires private key files to have these permissions — it will refuse to use the key if others can read it.
```
6 = read + write (owner)
0 = no permissions (group)
0 = no permissions (others)
```
```bash
chmod 600 /tmp/pi_key         # lock down private key file
```

## SSH with Key and Remote Command
```bash
ssh -i /tmp/pi_key -o StrictHostKeyChecking=no user@host "mkdir -p ~/reptrack"
```

| Part | Meaning |
|------|---------|
| `-i /tmp/pi_key` | use this file as the private key |
| `-o StrictHostKeyChecking=no` | skip "are you sure you want to connect?" prompt (needed for automation) |
| `user@host` | who to connect as and where |
| `"mkdir -p ~/reptrack"` | command to run on the remote machine after connecting |

## UserGroup Primer

**Unix was built for multiple users sharing one machine.** So it needed a way to control who can access what.

**Users** answered "who are you." But what if two users need to share something, without exposing it to everyone?

**Groups** solved that:
```
alice  ─┐
bob    ─┴─ developers group  →  can access /projects
charlie ── interns group     →  cannot
```

A file has three permission layers — owner, group, everyone else:
```
-rw-rw----  alice  developers  project.rb
# alice can read/write, developers can read/write, others — nothing
```

**Docker reused this exact idea:**
- Daemon runs as `root`
- Socket owned by `root:docker`
- Want access? Admin explicitly adds you to `docker` group

```bash
sudo usermod -aG docker rpi02  # add user rpi02 to docker group
# -a = append (don't replace existing groups)
# -G = groups to add to
```

The intention: **nothing is trusted by default, access must be explicitly granted.**