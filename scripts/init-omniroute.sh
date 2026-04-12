#!/usr/bin/env bash
# ================================================================
#  scripts/init-omniroute.sh — Khởi tạo data lần đầu
#
#  Mục đích:
#    Chạy OmniRoute ở init mode để tạo database mới và replicate
#    lên S3. Sau bước này, các lần deploy sau sẽ restore từ S3.
#
#  Sử dụng:
#    bash scripts/init-omniroute.sh
#
#  Yêu cầu:
#    - .env đã được cấu hình đầy đủ (LITESTREAM_S3_*, OMNIROUTE_*)
#    - S3 bucket chưa có data (hoặc muốn ghi đè)
#    - Docker đang chạy
#
#  Workflow:
#    1. Script này start container với LITESTREAM_INIT_MODE=true
#    2. Mở dashboard tại http://localhost:${APP_HOST_PORT:-20128}
#    3. Cấu hình providers, combos, API keys theo nhu cầu
#    4. Nhấn Enter để dừng container → litestream sẽ flush WAL lên S3
#    5. Từ lần deploy sau: container sẽ restore từ S3 tự động
# ================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo ""
echo "════════════════════════════════════════════════════════"
echo "  OmniRoute — Init Mode"
echo "════════════════════════════════════════════════════════"
echo ""

# ── Load .env ─────────────────────────────────────────────────
if [ ! -f "$ROOT_DIR/.env" ]; then
  echo "❌ Không tìm thấy .env. Hãy tạo từ .env.example trước:"
  echo "   cp .env.example .env"
  exit 1
fi

set -a
# shellcheck source=/dev/null
source "$ROOT_DIR/.env"
set +a

# ── Validate S3 vars trước khi chạy ───────────────────────────
MISSING=""
for var in \
  LITESTREAM_S3_ENDPOINT \
  LITESTREAM_S3_BUCKET \
  LITESTREAM_S3_ACCESS_KEY_ID \
  LITESTREAM_S3_SECRET_ACCESS_KEY \
  OMNIROUTE_JWT_SECRET \
  OMNIROUTE_API_KEY_SECRET \
  STORAGE_ENCRYPTION_KEY \
  OMNIROUTE_INITIAL_PASSWORD; do
  if [ -z "${!var:-}" ]; then
    MISSING="$MISSING\n  - $var"
  fi
done

if [ -n "$MISSING" ]; then
  echo "❌ Thiếu các biến bắt buộc trong .env:"
  printf "%b\n" "$MISSING"
  exit 1
fi

echo "✅ Env hợp lệ. Tiến hành khởi động init mode..."
echo ""
echo "📋 S3 Config:"
echo "   Endpoint : $LITESTREAM_S3_ENDPOINT"
echo "   Bucket   : $LITESTREAM_S3_BUCKET"
echo "   Path     : ${LITESTREAM_S3_PATH:-omniroute/storage.sqlite}"
echo ""

# Cảnh báo nếu đã có data trên S3
echo "⚠️  Nếu S3 đã có data, init mode sẽ GHI ĐÈ sau khi bạn dừng container."
read -r -p "   Tiếp tục? [y/N] " confirm
case "$confirm" in
  [yY][eE][sS]|[yY]) echo "" ;;
  *)
    echo "Hủy."
    exit 0
    ;;
esac

# ── Start với LITESTREAM_INIT_MODE=true ───────────────────────
echo "🚀 Khởi động OmniRoute (init mode)..."
echo "   Dashboard: http://localhost:${APP_HOST_PORT:-20128}"
echo ""
echo "   → Cấu hình providers, combos, API keys trong dashboard"
echo "   → Sau khi xong, nhấn Ctrl+C hoặc Enter để dừng"
echo ""

LITESTREAM_INIT_MODE=true \
  bash "$ROOT_DIR/docker-compose/scripts/dc.sh" up --build app

# Khi user Ctrl+C, dc.sh sẽ dừng. Litestream cần stop_grace_period=40s để flush.
echo ""
echo "⏳ Đang chờ litestream flush WAL lên S3 (stop_grace_period=40s)..."
sleep 5

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ Init hoàn tất!"
echo ""
echo "   Data đã được replicate lên S3:"
echo "   Endpoint : $LITESTREAM_S3_ENDPOINT"
echo "   Bucket   : $LITESTREAM_S3_BUCKET"
echo "   Path     : ${LITESTREAM_S3_PATH:-omniroute/storage.sqlite}"
echo ""
echo "   Từ lần deploy sau, container sẽ tự restore từ S3."
echo "   LITESTREAM_INIT_MODE phải là 'false' (hoặc bỏ trống)."
echo "════════════════════════════════════════════════════════"
echo ""
