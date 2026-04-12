# CHANGE LOGS (Developer-facing)

---

## [2026-04-12] swap-app-omniroute-litestream

### Changed

- `compose.apps.yml`: Thay app service → OmniRoute (`diegosouzapw/omniroute:latest`) với litestream wrapper
  - `stop_grace_period: 40s` để flush WAL trước khi node bị replace
  - Volume bind: `.docker-volumes/app/data:/app/data`
  - Health check: `wget http://localhost:${APP_PORT}/`
  - Env: `OMNIROUTE_DISABLE_AUTO_BACKUP=true` (litestream lo backup)
- `services/app/Dockerfile`: Multi-stage build — copy litestream binary từ `litestream/litestream:0.3.13`, wrap trên `diegosouzapw/omniroute:latest`
- `services/app/entrypoint.sh`: Restore logic — fail hard nếu không có S3 data (normal mode); skip nếu `LITESTREAM_INIT_MODE=true`
- `services/app/litestream.yml`: Config litestream với S3 endpoint/bucket/path qua env vars, `sync-interval: 10s`
- `docker-compose/scripts/validate-env.js`: Thêm validation cho `OMNIROUTE_JWT_SECRET`, `OMNIROUTE_API_KEY_SECRET`, `STORAGE_ENCRYPTION_KEY` (64 hex chars), `OMNIROUTE_INITIAL_PASSWORD`, `LITESTREAM_S3_*`
- `.env.example`: Thêm section OmniRoute + Litestream/Supabase S3
- `docs/services/app.md`: Rewrite hoàn toàn cho OmniRoute
- `docker-compose/scripts/dc.sh`: `prepare_docker_volume_dirs` — đổi `app/logs` → `app/data`

### Added

- `scripts/init-omniroute.sh`: Helper script cho workflow init lần đầu (validate env → start với LITESTREAM_INIT_MODE=true → hướng dẫn user)

### Removed

- `services/app/index.js`: Không còn cần (dùng omniroute image)
- `services/app/package.json`: Không còn cần

### Notes

- `STORAGE_ENCRYPTION_KEY` phải stable — không đổi sau khi có data
- `APP_PORT` default đổi thành `20128` (port mặc định của OmniRoute)
- `LITESTREAM_INIT_MODE` chỉ dùng local, không deploy với `true`

## [2.0.0] — 2026-04-09

### Breaking Changes

- `docker-compose.yml` split into 4 module files — must use `docker-compose/scripts/dc.sh` (or `-f docker-compose/compose.core.yml -f docker-compose/compose.ops.yml -f docker-compose/compose.access.yml -f compose.apps.yml`) instead of plain `docker compose`
- Env var renames: `DOMAIN` replaces individual `SUBDOMAIN_*` vars; `STACK_NAME` replaces `COMPOSE_PROJECT_NAME`; `PROJECT_NAME` is new (required)
- `TAILSCALE_CLIENT_SECRET` → `TAILSCALE_AUTHKEY` (standardised Tailscale env naming)
- `APP_PORT` now drives the app container port directly; `SUBDOMAIN_APP`, `SUBDOMAIN_DOZZLE`, etc. removed

### Added

- **`docker-compose/scripts/dc.sh`** — main orchestrator: loads `.env`, reads `ENABLE_*` flags, builds `--profile` args, calls all 4 compose files in one command
- **`docker-compose/compose.core.yml`** — caddy + cloudflared, network + volumes definition; always-on
- **`docker-compose/compose.ops.yml`** — dozzle, filebrowser, webssh, webssh-windows; all profile-gated
- **`docker-compose/compose.access.yml`** — tailscale-linux, tailscale-windows; profile-gated
- **`compose.apps.yml`** — parameterised app service (`APP_IMAGE` + `APP_PORT`)
- **`docker-compose/scripts/up.sh` / `docker-compose/scripts/down.sh` / `docker-compose/scripts/logs.sh`** — one-liner shortcuts wrapping `dc.sh`
- **`docker-compose/scripts/validate-env.js`** — checks required vars, format validation (bcrypt, domain, port), subdomain preview
- **`docker-compose/scripts/validate-ts.js`** — Tailscale auth key format check + optional expiry lookup via TS API
- **`docker-compose/scripts/validate-compose.js`** — runs `docker compose config` across all 4 files to catch YAML errors
- **`npm run dockerapp-validate:all`** — combined validation pipeline (env → compose → TS)
- **`docs/DEPLOY.md`** — full deployment guide with mermaid flow diagrams, use cases, security checklist
- Subdomain auto-convention: all routes derived from `${PROJECT_NAME}.${DOMAIN}` pattern
- `DC_VERBOSE=1` debug flag for `docker-compose/scripts/dc.sh`
- `HEALTH_PATH` env to customise healthcheck endpoint per image

### Changed

- Image versions pinned (caddy `2.9.1-alpine`, cloudflared `2025.1.0`, dozzle `v8.x`, filebrowser `v2.30.0`, tailscale `stable`)
- Caddy `CADDY_INGRESS_NETWORKS` now uses `${STACK_NAME}_net` (was `app_net`)
- Network name: `${STACK_NAME:-mystack}_net` (dynamic, avoids conflicts between stacks)
- GitHub Actions and Azure Pipelines updated to call `docker-compose/scripts/dc.sh up` instead of bare `docker compose up`
- `detect-os.sh` no longer writes `COMPOSE_PROFILES` (profiles now fully managed by `docker-compose/scripts/dc.sh`)
- `.env.example` fully rewritten to match new schema

### Removed

- Monolithic `docker-compose.yml` (replaced by 4 module files)
- `SUBDOMAIN_APP`, `SUBDOMAIN_DOZZLE`, `SUBDOMAIN_FILEBROWSER`, `SUBDOMAIN_WEBSSH` env vars
- `TAILSCALE_CLIENT_SECRET` (use `TAILSCALE_AUTHKEY`)
- Hardcoded `build: ./services/app` in compose (now `APP_IMAGE` param)
- `scripts/generate-cf-config.js` and the generated-config workflow (maintain `cloudflared/config.yml` manually)

---
