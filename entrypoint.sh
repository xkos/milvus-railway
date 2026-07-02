#!/bin/bash
set -e

MILVUS_CHILD_PID=""

stop_milvus() {
    if [ -n "$MILVUS_CHILD_PID" ] && kill -0 "$MILVUS_CHILD_PID" 2>/dev/null; then
        echo "Stopping Milvus child process ${MILVUS_CHILD_PID}..."
        kill -TERM "$MILVUS_CHILD_PID" 2>/dev/null || true
        wait "$MILVUS_CHILD_PID" 2>/dev/null || true
    fi
}

trap stop_milvus TERM INT

echo "Starting Milvus standalone..."

# Modify milvus.yaml with password configuration
echo "Modifying Milvus configuration..."

# Get password from environment variable or use default
MILVUS_PASSWORD="${MILVUS_ROOT_PASSWORD:-Milvus}"

if [ "$MILVUS_PASSWORD" != "Milvus" ]; then
    echo "Using custom password from MILVUS_ROOT_PASSWORD"
else
    echo "Using default password 'Milvus'"
    echo "Set MILVUS_ROOT_PASSWORD environment variable for production."
fi

# Modify /milvus/configs/milvus.yaml using sed
CONFIG_FILE="/milvus/configs/milvus.yaml"

if [ -f "$CONFIG_FILE" ]; then
    # Enable authorization
    sed -i 's/authorizationEnabled: false/authorizationEnabled: true/g' "$CONFIG_FILE"

    # Set root password (handle various possible formats)
    sed -i "s/defaultRootPassword:.*/defaultRootPassword: $MILVUS_PASSWORD/g" "$CONFIG_FILE"

    echo "Configuration modified successfully"
else
    echo "Warning: $CONFIG_FILE not found"
    exit 1
fi

USER_CONFIG_FILE="/milvus/configs/user.yaml"
if [ -f "$USER_CONFIG_FILE" ]; then
    # Enable authorization
    sed -i 's/authorizationEnabled: false/authorizationEnabled: true/g' "$USER_CONFIG_FILE"

    # Set root password (handle various possible formats)
    sed -i "s/defaultRootPassword:.*/defaultRootPassword: $MILVUS_PASSWORD/g" "$USER_CONFIG_FILE"

    echo "Configuration user successfully"
fi

# Keep restart control inside the container. This avoids Railway rapidly
# recreating the container while embedded etcd is still recovering/electing.
attempt=0
while true; do
    attempt=$((attempt + 1))
    echo "Starting Milvus process, attempt=${attempt}..."

    /milvus/bin/milvus run standalone &
    MILVUS_CHILD_PID=$!

    set +e
    wait "$MILVUS_CHILD_PID"
    code=$?
    set -e
    MILVUS_CHILD_PID=""

    if [ "$code" = "0" ]; then
        echo "Milvus exited cleanly."
        exit 0
    fi

    echo "Milvus exited with code ${code}."

    if [ "$attempt" -lt 3 ]; then
        delay=15
    elif [ "$attempt" -lt 6 ]; then
        delay=30
    else
        delay=60
    fi

    echo "Waiting ${delay}s before restarting Milvus..."
    sleep "$delay"
done
