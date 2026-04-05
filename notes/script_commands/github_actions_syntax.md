# GitHub Actions Syntax Reference

## Expressions
```yaml
${{ secrets.MY_SECRET }}     # access a secret
${{ github.sha }}            # current commit hash
${{ github.ref }}            # branch/tag
${{ github.actor }}          # who triggered it
${{ github.repository }}     # owner/repo-name
${{ github.event_name }}     # push, pull_request, etc.
${{ env.MY_VAR }}            # environment variable
${{ inputs.my_input }}       # manual trigger input
${{ runner.os }}             # Linux, macOS, Windows
${{ runner.arch }}           # X64, ARM64
```

## Triggers (`on:`)
```yaml
on:
  push:
    branches: [ main ]
  pull_request:
  schedule:
    - cron: '0 0 * * *'
  workflow_dispatch:        # manual trigger
```

## Environment Variables
```yaml
env:
  MY_VAR: "value"           # global
jobs:
  my_job:
    env:
      MY_VAR: "value"       # job level
    steps:
      - env:
          MY_VAR: "value"   # step level
```

## Conditions
```yaml
if: github.ref == 'refs/heads/main'
if: failure()
if: success()
```

## Needs (job dependencies)
```yaml
jobs:
  deploy:
    needs: build            # waits for build job first
```

## Matrix (run job with multiple configs)
```yaml
strategy:
  matrix:
    ruby: [3.1, 3.2, 3.3]
```

## Artifacts (share files between jobs)
```yaml
- uses: actions/upload-artifact@v4
  with:
    name: my-file
    path: output/

- uses: actions/download-artifact@v4
  with:
    name: my-file
```

## Timeout
```yaml
jobs:
  my_job:
    timeout-minutes: 10
```

## Continue on Error
```yaml
- name: my step
  continue-on-error: true
```

## Job/Step Outputs
```yaml
${{ jobs.my_job.outputs.my_output }}
${{ steps.my_step.outputs.my_output }}
```

## Expressions (conditions, logic)
```yaml
${{ github.ref == 'refs/heads/main' }}
${{ contains(github.event.head_commit.message, 'skip ci') }}
```
