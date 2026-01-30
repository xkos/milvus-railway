#!/bin/bash
set -e

echo "Starting Milvus standalone..."

# Modify milvus.yaml with password configuration
echo "Modifying Milvus configuration..."

# Get password from environment variable or use default
MILVUS_PASSWORD="${MILVUS_ROOT_PASSWORD:-Milvus}"

if [ "$MILVUS_PASSWORD" != "Milvus" ]; then
    echo "✓ Using custom password from MILVUS_ROOT_PASSWORD"
else
    echo "⚠️  Using default password 'Milvus'"
    echo "   Set MILVUS_ROOT_PASSWORD environment variable for production!"
fi

# Modify /milvus/configs/milvus.yaml using sed
CONFIG_FILE="/milvus/configs/milvus.yaml"

if [ -f "$CONFIG_FILE" ]; then
    # Enable authorization
    sed -i 's/authorizationEnabled: false/authorizationEnabled: true/g' "$CONFIG_FILE"
    
    # Set root password (handle various possible formats)
    sed -i "s/defaultRootPassword:.*/defaultRootPassword: $MILVUS_PASSWORD/g" "$CONFIG_FILE"
    
    echo "✓ Configuration modified successfully"
else
    echo "⚠️  Warning: $CONFIG_FILE not found"
    exit 1
fi

# Start Milvus in standalone mode
echo "Starting Milvus..."
exec /milvus/bin/milvus run standalone
