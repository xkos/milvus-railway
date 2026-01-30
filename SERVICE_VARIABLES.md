# Milvus Railway Service Variables 使用示例

## 变量说明

当 Milvus 服务部署到 Railway 后，会自动暴露以下服务变量：

- `MILVUS_HOST`: Milvus 服务的私有域名
- `MILVUS_PORT`: 19530 (gRPC 端口)
- `MILVUS_GRPC_PORT`: 19530
- `MILVUS_METRICS_PORT`: 9091
- `MILVUS_ETCD_PORT`: 2379
- `MILVUS_URI`: http://[私有域名]:19530

## 在其他 Railway 服务中引用

### 方法1: 在 Railway UI 中配置

在你的应用服务的 Variables 页面添加：

```
MILVUS_HOST=${{milvus-standalone.MILVUS_HOST}}
MILVUS_PORT=${{milvus-standalone.MILVUS_PORT}}
MILVUS_URI=${{milvus-standalone.MILVUS_URI}}
```

注意：`milvus-standalone` 是你的 Milvus 服务名称，需要替换为实际的服务名。

### 方法2: 在代码中直接使用环境变量

## Python 示例

```python
import os
from pymilvus import connections, Collection, FieldSchema, CollectionSchema, DataType

# 连接到 Milvus
connections.connect(
    alias="default",
    host=os.getenv('MILVUS_HOST'),
    port=os.getenv('MILVUS_PORT', '19530')
)

# 创建 Collection
fields = [
    FieldSchema(name="id", dtype=DataType.INT64, is_primary=True, auto_id=True),
    FieldSchema(name="embedding", dtype=DataType.FLOAT_VECTOR, dim=128)
]
schema = CollectionSchema(fields=fields, description="Test collection")
collection = Collection(name="test_collection", schema=schema)

print("✓ Connected to Milvus successfully!")
```

## Node.js 示例

```javascript
const { MilvusClient } = require('@zilliz/milvus2-sdk-node');

const client = new MilvusClient({
  address: process.env.MILVUS_HOST,
  port: process.env.MILVUS_PORT || '19530'
});

async function main() {
  // 测试连接
  const version = await client.getVersion();
  console.log('✓ Connected to Milvus:', version);
  
  // 创建 Collection
  await client.createCollection({
    collection_name: 'test_collection',
    fields: [
      {
        name: 'id',
        description: 'ID field',
        data_type: 'Int64',
        is_primary_key: true,
        autoID: true
      },
      {
        name: 'embedding',
        description: 'Vector field',
        data_type: 'FloatVector',
        dim: 128
      }
    ]
  });
}

main().catch(console.error);
```

## Go 示例

```go
package main

import (
    "context"
    "fmt"
    "log"
    "os"

    "github.com/milvus-io/milvus-sdk-go/v2/client"
    "github.com/milvus-io/milvus-sdk-go/v2/entity"
)

func main() {
    ctx := context.Background()
    
    // 从环境变量获取连接信息
    milvusAddr := fmt.Sprintf("%s:%s",
        os.Getenv("MILVUS_HOST"),
        getEnvOrDefault("MILVUS_PORT", "19530"))
    
    // 连接到 Milvus
    c, err := client.NewGrpcClient(ctx, milvusAddr)
    if err != nil {
        log.Fatal("failed to connect to Milvus:", err)
    }
    defer c.Close()
    
    // 创建 Collection
    schema := &entity.Schema{
        CollectionName: "test_collection",
        Description:    "Test collection",
        Fields: []*entity.Field{
            {
                Name:       "id",
                DataType:   entity.FieldTypeInt64,
                PrimaryKey: true,
                AutoID:     true,
            },
            {
                Name:     "embedding",
                DataType: entity.FieldTypeFloatVector,
                TypeParams: map[string]string{
                    "dim": "128",
                },
            },
        },
    }
    
    err = c.CreateCollection(ctx, schema, 2)
    if err != nil {
        log.Fatal("failed to create collection:", err)
    }
    
    fmt.Println("✓ Connected to Milvus successfully!")
}

func getEnvOrDefault(key, defaultValue string) string {
    if value := os.Getenv(key); value != "" {
        return value
    }
    return defaultValue
}
```

## Docker Compose 示例

如果你在 Railway 上部署其他容器化服务：

```yaml
version: '3.8'

services:
  app:
    image: your-app:latest
    environment:
      # 在 Railway 中会自动替换
      - MILVUS_HOST=${MILVUS_HOST}
      - MILVUS_PORT=${MILVUS_PORT}
      - MILVUS_URI=${MILVUS_URI}
```

## FastAPI 示例

```python
from fastapi import FastAPI
from pymilvus import connections
import os

app = FastAPI()

@app.on_event("startup")
async def startup_event():
    connections.connect(
        alias="default",
        host=os.getenv('MILVUS_HOST'),
        port=os.getenv('MILVUS_PORT', '19530')
    )
    print("✓ Connected to Milvus")

@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "milvus_host": os.getenv('MILVUS_HOST'),
        "milvus_port": os.getenv('MILVUS_PORT')
    }
```

## 注意事项

1. **私有网络**: 这些变量使用 Railway 的私有网络地址，只能在同一 Railway 项目的服务之间访问
2. **服务名称**: 确保引用变量时使用正确的服务名称（默认是 `milvus-standalone`）
3. **端口**: Milvus 的主要连接端口是 19530 (gRPC)
4. **健康检查**: 可以通过 9091 端口的 `/healthz` 端点检查服务状态
