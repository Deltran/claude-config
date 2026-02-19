# pv-build Project Memory

## Deploy Service (Slack-triggered)
- Full implementation complete with 100% test coverage
- Architecture: Slack → devprocess (deploy_service.py :8090) → SSH → newadmin (pv-deploy script)
- See [deploy-service.md](deploy-service.md) for details

## Server Details
- **devprocess**: devprocess.packetviper.com — runs deploy service, nginx, claude-review
- **newadmin**: 3.92.69.252 (public), 172.31.42.133 (private) — hosts backoffice app
- Both in same VPC (172.31.x.x), SSH between them uses private IP
- devprocess internal IP: 172.31.83.206

## Backoffice App
- Monorepo at `/var/www/backoffice`, tooltips app at `apps/tooltips`
- Default branch is `master` (not main)
- Laravel 12, PHP 8.4 (upgraded from 8.3), Node 22
- Web server runs as `nginx` user
- RDS: pvbackend.cluster-cn4fincxd4zs.us-east-1.rds.amazonaws.com, database: pvdb

## Key Patterns
- Amazon Linux 2023 uses `dnf` not `yum`
- PHP upgrade: `dnf install --allowerasing` to swap major versions atomically
- Config files sourced in bash: values with spaces MUST be quoted
- pv-deploy script uses env vars for testability: PV_DEPLOY_CONFIG_DIR, PV_DEPLOY_SKIP_ROOT_CHECK
