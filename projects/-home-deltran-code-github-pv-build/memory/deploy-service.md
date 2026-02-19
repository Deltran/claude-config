# Deploy Service Details

## Code Structure
```
src/deploy-service/
├── deploy_service.py      # HTTP server + handler (port 8090)
├── slack_auth.py          # HMAC-SHA256 signature verification
├── command_parser.py      # Parse /deploy text → target + branch
├── lock_manager.py        # JSON lock files per target
├── deploy_runner.py       # SSH subprocess execution
├── slack_notifier.py      # Slack chat.postMessage API
├── config_loader.py       # YAML config loading + validation
└── deploy_targets.yaml    # Target configuration

scripts/pv-deploy           # Bash deploy script (installed on target servers)
systemd/pv-deploy.service   # Systemd unit
config/deploy-credentials.template
deploy-deploy-service.sh    # Installs service to devprocess
docs/deploy-service-setup.md
docs/fix-backoffice-tests.md  # Instructions for fixing phpunit.xml
```

## Test Coverage
- 59 Python tests (pytest + pytest-cov, 100% coverage)
- 13 bats tests for pv-deploy bash script
- Tests in `tests/deploy-service/`

## Deployment Status (as of Feb 2026)
- Service files installed on devprocess at /opt/deploy-service/
- nginx location block added, reloaded
- systemd unit installed but NOT started (waiting for Slack credentials)
- newadmin: deploy user, SSH keys, pv-deploy script, sudoers, backoffice.conf all set
- MySQL backoffice_deploy user created on RDS
- SSH chain verified working

## Blockers
- Slack app needs to be created by user → tokens go in /etc/deploy-service/credentials
- Backoffice tests need phpunit.xml fix (SQLite in-memory) → docs/fix-backoffice-tests.md
- Code not yet committed/pushed (user wants to review first)

## Users
| User | Where | Purpose |
|------|-------|---------|
| deploy-svc | devprocess | Runs deploy service, SSHs to targets |
| deploy | newadmin | Receives SSH, runs pv-deploy via sudo |
| backoffice_deploy | MySQL/RDS | Runs migrations (limited grants) |
