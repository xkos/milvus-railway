#!/bin/bash
set -e

echo "Starting Milvus standalone..."

# Generate user.yaml with password configuration
echo "Generating Milvus configuration..."

# Get password from environment variable or use default
MILVUS_PASSWORD="${MILVUS_ROOT_PASSWORD:-Milvus}"

if [ "$MILVUS_PASSWORD" != "Milvus" ]; then
    echo "✓ Using custom password from MILVUS_ROOT_PASSWORD"
else
    echo "⚠️  Using default password 'Milvus'"
    echo "   Set MILVUS_ROOT_PASSWORD environment variable for production!"
fi

# Generate user.yaml dynamically
cat > /milvus/user.yaml << EOF
# Auto-generated Milvus configuration
# Generated at: $(date)

# Enable authentication
common:
  security:
    authorizationEnabled: true
    # Initial root password (auto-configured from MILVUS_ROOT_PASSWORD)
    defaultRootPassword: "$MILVUS_PASSWORD"

# Log configuration
log:
  level: info

# Proxy configuration
# proxy:
#   port: 19530
EOF

echo "✓ Configuration generated successfully"

# Start Milvus in standalone mode
echo "Starting Milvus..."
exec /milvus/bin/milvus run standalone
