FROM milvusdb/milvus:v2.4.17

# Set working directory
WORKDIR /milvus

# Create necessary directories
RUN mkdir -p /var/lib/milvus/etcd /var/lib/milvus/data

# Copy configuration files
COPY embedEtcd.yaml /milvus/configs/embedEtcd.yaml
COPY user.yaml /milvus/configs/user.yaml

# Set environment variables
ENV ETCD_USE_EMBED=true \
    ETCD_DATA_DIR=/var/lib/milvus/etcd \
    ETCD_CONFIG_PATH=/milvus/configs/embedEtcd.yaml \
    COMMON_STORAGETYPE=local \
    DEPLOY_MODE=STANDALONE

# Expose ports
# 19530: Milvus gRPC port
# 9091: Milvus metrics port
# 2379: etcd client port
EXPOSE 19530 9091 2379

# Health check
HEALTHCHECK --interval=30s --timeout=20s --start-period=90s --retries=3 \
    CMD curl -f http://localhost:9091/healthz || exit 1

# Start Milvus in standalone mode
CMD ["milvus", "run", "standalone"]
