# OmniRoute — AI Gateway Service

## Overview

Service `app` chạy [OmniRoute](https://github.com/diegosouzapw/OmniRoute) — một AI gateway OpenAI-compatible với smart routing, load balancing, và fallback tự động qua 36+ providers.

Data được lưu bằng **SQLite** (cục bộ) và replicate lên **Supabase S3** qua **litestream**, đảm bảo không mất data khi node bị thay thế (GitHub Actions / Azure Pipelines mỗi 50 phút).

---

## Startup Flow

```
Container start
  │
  ├─ LITESTREAM_INIT_MODE=true ?
  │     └─ Bỏ qua restore → OmniRoute tạo DB mới → replicate lên S3
  │
  └─ LITESTREAM_INIT_MODE=false (default) ?
        ├─ litestream restore từ S3
        ├─ Không có file → exit 1 (operator phải xử lý tay)
        └─ Restore xong → litestream replicate + OmniRoute khởi động
```

---

## Lần đầu triển khai (Init)

```bash
# 1. Cấu hình .env đầy đủ
cp .env.example .env
# ... điền các giá trị OMNIROUTE_*, LITESTREAM_S3_*, ...

# 2. Chạy init script để tạo data và upload lên S3
bash scripts/init-omniroute.sh

# 3. Cấu hình qua dashboard: http://localhost:20128
#    - Thêm providers, API keys, combos...

# 4. Dừng (script tự làm) → litestream flush WAL lên S3

# 5. Từ lần sau, deploy bình thường (LITESTREAM_INIT_MODE=false)
```

---

## Required Env

### OmniRoute Secrets (KHÔNG ĐỔI sau khi có data)

| Key | Mô tả | Tạo bằng |
|-----|-------|----------|
| `OMNIROUTE_JWT_SECRET` | JWT signing secret | `openssl rand -base64 48` |
| `OMNIROUTE_API_KEY_SECRET` | API key HMAC secret | `openssl rand -hex 32` |
| `STORAGE_ENCRYPTION_KEY` | AES-256-GCM key cho credentials | `openssl rand -hex 32` |
| `STORAGE_ENCRYPTION_KEY_VERSION` | Key version (default: `v1`) | — |
| `OMNIROUTE_INITIAL_PASSWORD` | Mật khẩu dashboard lần đầu | — |

### Litestream / Supabase S3

| Key | Mô tả |
|-----|-------|
| `LITESTREAM_S3_ENDPOINT` | `https://<project>.supabase.co/storage/v1/s3` |
| `LITESTREAM_S3_BUCKET` | Tên bucket trong Supabase Storage |
| `LITESTREAM_S3_PATH` | Prefix path (default: `omniroute/storage.sqlite`) |
| `LITESTREAM_S3_ACCESS_KEY_ID` | Supabase S3 access key |
| `LITESTREAM_S3_SECRET_ACCESS_KEY` | Supabase S3 secret key |
| `LITESTREAM_INIT_MODE` | `false` (default). `true` chỉ dùng khi init |

### App

| Key | Mô tả | Default |
|-----|-------|---------|
| `APP_PORT` | Port nội bộ container | `20128` |
| `APP_HOST_PORT` | Port expose trên host | `20128` |
| `OMNIROUTE_BASE_URL` | Public base URL | `http://localhost:20128` |

---

## Data Storage

| File | Nội dung |
|------|----------|
| `/app/data/storage.sqlite` | Toàn bộ config: providers, combos, API keys, settings |
| `/app/data/log.txt` | Application logs (optional) |
| `/app/data/call_logs/` | Request call logs (optional) |

Volume bind: `${DOCKER_VOLUMES_ROOT}/app/data:/app/data`

---

## Supabase S3 Setup

1. Vào **Supabase Dashboard → Storage → Buckets** → tạo bucket mới
2. Vào **Project Settings → Storage → S3 Access Keys** → tạo access key
3. Điền vào `.env`:
   ```dotenv
   LITESTREAM_S3_ENDPOINT=https://<project-id>.supabase.co/storage/v1/s3
   LITESTREAM_S3_BUCKET=omniroute-data
   LITESTREAM_S3_ACCESS_KEY_ID=<access-key-id>
   LITESTREAM_S3_SECRET_ACCESS_KEY=<secret-key>
   ```

---

## Dashboard

Truy cập: `http://${PROJECT_NAME}.${DOMAIN}` hoặc `http://localhost:${APP_HOST_PORT}`

- **Providers**: Kết nối Claude Code, Gemini CLI, iFlow, OpenRouter...
- **Combos**: Tạo nhóm model với fallback tự động
- **Analytics**: Token usage, cost tracking, latency
- **Health**: Circuit breaker states, rate limits

---

## Security Notes

- `STORAGE_ENCRYPTION_KEY` mã hóa AES-256-GCM cho tất cả API keys và OAuth tokens trong DB
- **Không bao giờ đổi** key này sau khi đã có data — sẽ mất toàn bộ credentials
- Thêm vào CI secrets, không commit vào repo
