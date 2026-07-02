FROM quay.io/coreos/etcd:v3.5.23 AS etcd

FROM milvusdb/milvus:v2.6.11

# Create necessary directories
RUN mkdir -p /var/lib/milvus/etcd /var/lib/milvus/data

# Run etcd as a separate process in the same container so Milvus can wait for
# it to become healthy before starting coordinators.
COPY --from=etcd /usr/local/bin/etcd /usr/local/bin/etcd
COPY --from=etcd /usr/local/bin/etcdctl /usr/local/bin/etcdctl

# Copy configuration files
COPY embedEtcd.yaml /milvus/configs/embedEtcd.yaml
COPY user.yaml /milvus/configs/user.yaml
COPY entrypoint.sh /milvus/entrypoint.sh

# Make entrypoint executable
RUN chmod +x /milvus/entrypoint.sh

# Set environment variables
ENV ETCD_USE_EMBED=false \
    ETCD_DATA_DIR=/var/lib/milvus/etcd \
    ETCD_ENDPOINTS=127.0.0.1:2379 \
    ETCD_CONFIG_PATH=/milvus/configs/embedEtcd.yaml \
    ETCD_LOG_LEVEL=error \
    COMMON_STORAGETYPE=local \
    DEPLOY_MODE=STANDALONE


# Expose ports
# 19530: Milvus gRPC port
# 9091: Milvus metrics port
# 2379: etcd client port
EXPOSE 19530 9091 2379

# Health check
HEALTHCHECK --interval=30s --timeout=20s --start-period=300s --retries=10 \
    CMD curl -f http://localhost:9091/healthz || exit 1

# Use custom entrypoint for password management
ENTRYPOINT ["/milvus/entrypoint.sh"]
