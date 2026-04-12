#!/bin/sh
# ================================================================
#  entrypoint.sh — OmniRoute + Litestream startup
#
#  Image gốc: diegosouzapw/omniroute:latest
#    ENTRYPOINT = docker-entrypoint.sh
#    CMD        = node run-standalone.mjs
#    WORKDIR    = /app
#
#  Litestream v0.3.x dùng -exec "cmd" thay vì -- cmd
# ================================================================
set -e

DATA_DIR="${DATA_DIR:-/app/data}"
DB_PATH="${DATA_DIR}/storage.sqlite"

mkdir -p "$DATA_DIR"

if [ "${LITESTREAM_INIT_MODE:-false}" = "true" ]; then
  echo "🟡 [INIT MODE] Bỏ qua restore S3."
  echo "   OmniRoute sẽ tạo database mới tại: $DB_PATH"
  echo "   Data sẽ được litestream replicate lên S3 sau khi khởi động."
  echo "   → Cấu hình qua dashboard rồi Ctrl+C để dừng"
else
  echo "🔄 [RESTORE] Đang restore storage.sqlite từ S3..."

  if ! litestream restore \
      -config /etc/litestream.yml \
      -if-replica-exists \
      "$DB_PATH"; then
    echo ""
    echo "❌ [ERROR] Lỗi khi restore từ S3."
    echo "   Kiểm tra: LITESTREAM_S3_ENDPOINT, BUCKET, ACCESS_KEY."
    echo "   Nếu chạy lần đầu: bash scripts/init-omniroute.sh"
    exit 1
  fi

  if [ ! -f "$DB_PATH" ]; then
    echo ""
    echo "❌ [ERROR] Không tìm thấy backup trên S3."
    echo "   OmniRoute không khởi động để tránh mất dữ liệu."
    echo "   → Chạy init lần đầu: bash scripts/init-omniroute.sh"
    exit 1
  fi

  echo "✅ [RESTORE] Xong: $DB_PATH"
fi

echo "🚀 Khởi động OmniRoute + litestream replication..."

# ── Litestream v0.3.x: dùng -exec "cmd" để spawn subprocess ──
# Bọc qua docker-entrypoint.sh để giữ setup env của image gốc.
# $@ = CMD từ Docker = node run-standalone.mjs
if [ $# -gt 0 ]; then
  OMNIROUTE_CMD="docker-entrypoint.sh $*"
else
  OMNIROUTE_CMD="docker-entrypoint.sh node run-standalone.mjs"
fi

echo "   → exec: $OMNIROUTE_CMD"
exec litestream replicate -config /etc/litestream.yml -exec "$OMNIROUTE_CMD"
