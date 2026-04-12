# ================================================================
#  services/app/Dockerfile
#  Wrap diegosouzapw/omniroute với litestream binary
#
#  Image gốc:
#    ENTRYPOINT = ["docker-entrypoint.sh"]
#    CMD        = ["node", "run-standalone.mjs"]
#    WORKDIR    = /app
#
#  Startup flow:
#    entrypoint.sh → restore/skip S3 → litestream replicate
#      → docker-entrypoint.sh node run-standalone.mjs
# ================================================================

# ── Stage 1: lấy litestream binary ────────────────────────────
FROM litestream/litestream:0.3.13 AS litestream-bin

# ── Stage 2: wrap omniroute ────────────────────────────────────
FROM diegosouzapw/omniroute:latest

# Copy litestream binary từ stage 1
COPY --from=litestream-bin /usr/local/bin/litestream /usr/local/bin/litestream

# Copy litestream config và entrypoint của chúng ta
COPY litestream.yml /etc/litestream.yml
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Override ENTRYPOINT; giữ nguyên CMD từ image gốc (node run-standalone.mjs)
# CMD sẽ được forward qua $@ vào litestream replicate -- docker-entrypoint.sh "$@"
ENTRYPOINT ["/entrypoint.sh"]
