# Backoffice Project Memory

## Project Overview
- Laravel 12 + Livewire tooltip editor for PacketViper firewall product
- Located at `apps/tooltips/` within a monorepo
- Shared package at `packages/shared/` (User model, factories)

## Deployment Gotcha
- **Must run `npm run build` on production when adding new Tailwind classes**
- Tailwind JIT only includes classes present at build time — new classes silently have no effect without rebuilding
- Production CSS is at `apps/tooltips/public/build/assets/app-*.css`
- Node v22 and npm are available on production (newadmin)

## Key Patterns
- Tests run via `./vendor/bin/sail test` (Docker/Sail)
- TDD is mandatory per CLAUDE.md
- **User model is `PacketViper\Shared\Models\User`** — NOT `App\Models\User` (does not exist)
- In tests: `use PacketViper\Shared\Models\User;` — never `Shared\Models\User` or `App\Models\User`
- Sources with `ai_run_completed = false` block manual editing (Phase 3e)
- Test helpers that create TooltipSource must set `ai_run_completed => true` if tests involve saving/editing tooltips
- Tooltip JSON now uses nested format: `{"text": "...", "_lastUpdated": "YYYY-MM-DD"}`
- `TooltipSource::extractOriginalText()` handles both flat and nested formats

## Authorization Model (2026-02-16 refactor)
- **Old:** admin/sales/support booleans → **New:** can_admin/can_tooltips/can_context booleans
- Middleware: `admin` (checks can_admin), `app:tooltips` / `app:context` (checks can_* columns)
- Factory states: `->admin()`, `->withTooltips()`, `->withContext()`, `->withAllApps()`
- `User::hasAppAccess(string $app)` convenience method
- See CLAUDE.md "Adding a New App" checklist for onboarding new apps
- Context app has its own middleware copies in `apps/context/app/Http/Middleware/`
- Context app vendor not installed locally — tests can't run in dev currently

## Database Schema (after migrations)
- `backoffice_users`: can_admin, can_tooltips, can_context (booleans, default false) — old admin/sales/support columns removed
- `tooltips`: source_id, page, tooltip_key, tooltip_text, version, modified_by, modified_by_type (default 'human'), last_updated_at, ai_suggested_text, ai_suggestion_status (default 'none')
- `tooltip_sources`: source_type, github_branch, github_sha, original_json, loaded_by, ai_run_completed (default false), ai_job_id (nullable), ai_job_progress (json, nullable)

## AiSuggestionService (real API integration)
- `submitJob(sourceId, branch)` → POST /update-tooltips → stores job_id on source
- `pollJobStatus(sourceId)` → GET /jobs/{job_id} → stores progress on source
- `processCompletedJob(sourceId, resultJson)` → diffs result against DB, creates pending suggestions
- `checkStatus(sourceId)` → returns counts of pending/accepted/rejected
- Config: `services.tooltip_updater.url` (env: TOOLTIP_UPDATER_URL, default localhost:8042)
- TooltipEditor uses `wire:poll.3s="checkAiJobStatus"` while aiLoading=true
- Graceful degradation: if service unreachable, sets ai_run_completed=true so editing works

## Files Changed (2026-02-09 AI Integration)
- 4 migrations: last_updated_at, attribution, ai_suggestion_columns, ai_job_tracking
- Models: Tooltip.php, TooltipSource.php
- Service: AiSuggestionService.php (real HTTP client to tooltip-updater API)
- Livewire: TooltipEditor.php, TooltipRow.php, AddSectionRow.php
- Blades: tooltip-editor, tooltip-row, add-section-row
- Config: services.php (tooltip_updater section), .env.example
- 8 new test files, 2 existing test files updated
