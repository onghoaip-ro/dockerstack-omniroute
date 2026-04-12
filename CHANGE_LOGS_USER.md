# CHANGE LOGS (User-facing)

---

## [2026-04-12] OmniRoute AI Gateway

### Tính năng mới

- **OmniRoute** thay thế app cũ: dashboard AI gateway tại `http://<domain>` với 36+ providers (Claude, Gemini, OpenAI, Groq, iFlow...)
- **Tự động backup dữ liệu**: Mọi cấu hình (providers, combos, API keys) được sync lên Supabase S3 theo thời gian thực — không mất data khi node restart
- **Khôi phục tự động**: Node mới khởi động sẽ tự restore dữ liệu từ S3 trước khi mở cổng
- **Init script**: `scripts/init-omniroute.sh` để cấu hình lần đầu dễ dàng

### Thay đổi cấu hình

- `APP_PORT` đổi thành `20128` (port mặc định OmniRoute)
- Cần bổ sung các biến môi trường mới vào `.env` và CI secrets (xem `docs/services/app.md`)

## [2.0.0] — 2026-04-09 — Modular Stack Template

### What's New

**Deploy any Docker image in minutes**
Change two lines in `.env` (`APP_IMAGE` and `APP_PORT`) and your app is live — no YAML editing required.

**Feature flags — enable what you need**
Turn ops tools on or off with simple env vars:

```env
ENABLE_DOZZLE=true
ENABLE_FILEBROWSER=true
ENABLE_WEBSSH=false
ENABLE_TAILSCALE=false
```

**Subdomains auto-generated**
Set `PROJECT_NAME=gitea` and `DOMAIN=example.com` once. All service URLs follow automatically:

- `gitea.example.com` → your app
- `logs.gitea.example.com` → log viewer
- `files.gitea.example.com` → file manager
- `ttyd.gitea.example.com` → web terminal

**One-command validation before deploy**

```bash
npm run dockerapp-validate:all
```

Checks env vars, Tailscale key format, and compose YAML — all at once.

**One-command deploy**

```bash
npm run dockerapp-exec:up
```

### What Changed (migration from v1)

If upgrading from the previous `docker-compose.yml` setup:

1. Replace `SUBDOMAIN_APP/DOZZLE/FILEBROWSER/WEBSSH` with just `PROJECT_NAME`
2. Replace `TAILSCALE_CLIENT_SECRET` with `TAILSCALE_AUTHKEY`
3. Replace `docker compose up` with `bash docker-compose/scripts/dc.sh up` or `npm run dockerapp-exec:up`
4. Update `cloudflared/config.yml` manually from `cloudflared/config.yml.example` if you use Cloudflare Tunnel

See `docs/DEPLOY.md` for the full migration guide.

---
