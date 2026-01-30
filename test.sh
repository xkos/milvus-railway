#!/bin/bash

# Test script for Milvus connection
# Install pymilvus first: pip install pymilvus

cat << 'EOF' > test_connection.py
from pymilvus import connections, utility
import sys

def test_milvus_connection(host="localhost", port="19530"):
    try:
        print(f"Connecting to Milvus at {host}:{port}...")
        connections.connect(
            alias="default",
            host=host,
            port=port
        )
        
        print("✓ Connection successful!")
        
        # Check server version
        version = utility.get_server_version()
        print(f"✓ Milvus version: {version}")
        
        # List collections
        collections = utility.list_collections()
        print(f"✓ Current collections: {collections if collections else 'None'}")
        
        connections.disconnect("default")
        print("\n✅ All tests passed!")
        return True
        
    except Exception as e:
        print(f"\n❌ Connection failed: {str(e)}")
        return False

if __name__ == "__main__":
    host = sys.argv[1] if len(sys.argv) > 1 else "localhost"
    port = sys.argv[2] if len(sys.argv) > 2 else "19530"
    
    success = test_milvus_connection(host, port)
    sys.exit(0 if success else 1)
EOF

echo "Installing pymilvus..."
pip install pymilvus -q

echo ""
echo "Running connection test..."
python test_connection.py $@

# Clean up
rm test_connection.py
