# Milvus Railway Deployment

可以在 Railway 上部署的 Milvus Standalone 模式向量数据库项目。

## 特性

- 🚀 Milvus Standalone 模式（内嵌 etcd）
- 📦 本地存储（适合开发和测试）
- 💾 Railway Volume 持久化存储
- 🔒 支持通过环境变量配置密码
- 🏥 内置健康检查

## 快速开始

### 在 Railway 上部署

1. Fork 此仓库
2. 在 [Railway](https://railway.app) 创建新项目
3. 连接你的 GitHub 仓库
4. **（推荐）设置密码** - 在 Variables 添加：
   ```bash
   MILVUS_ROOT_PASSWORD=YourStrongPassword123!
   ```
5. Railway 自动检测配置并开始部署
6. 部署完成后获得公网访问地址

### 本地运行

```bash
# 使用自定义密码
docker build -t milvus-railway .
docker run -d \
  --name milvus-standalone \
  -e MILVUS_ROOT_PASSWORD=MyPassword123! \
  -p 19530:19530 \
  -p 9091:9091 \
  -v $(pwd)/volumes/milvus:/var/lib/milvus \
  milvus-railway

# 或使用 docker-compose
docker-compose up -d
```

### 连接到 Milvus

```python
from pymilvus import connections
import os

# 使用环境变量（推荐）
connections.connect(
    alias="default",
    host=os.getenv('MILVUS_HOST', 'localhost'),
    port=os.getenv('MILVUS_PORT', '19530'),
    user="root",
    password=os.getenv('MILVUS_ROOT_PASSWORD', 'Milvus')
)

# 或直接指定
connections.connect(
    alias="default",
    host="your-app.railway.app",
    port="19530",
    user="root",
    password="YourPassword123!"  # 你设置的密码
)
```

## 端口说明

- **19530**: Milvus gRPC 端口（主要连接端口，Railway 对外暴露）
- **9091**: Metrics 端口（健康检查，仅内部）
- **2379**: etcd 端口（仅内部）

## 环境变量

### MILVUS_ROOT_PASSWORD

设置 Milvus root 用户的初始密码。

```bash
# Railway Variables
MILVUS_ROOT_PASSWORD=YourStrongPassword123!

# Docker
docker run -e MILVUS_ROOT_PASSWORD=YourPassword ...

# Docker Compose
environment:
  - MILVUS_ROOT_PASSWORD=YourPassword
```

**如果未设置**：使用默认密码 `Milvus`

⚠️ **生产环境必须设置此变量！**

### 其他环境变量

以下变量已在 Dockerfile 中预配置：

- `PORT=19530` - Railway 对外暴露端口
- `ETCD_USE_EMBED=true` - 使用内嵌 etcd
- `ETCD_DATA_DIR=/var/lib/milvus/etcd` - etcd 数据目录
- `COMMON_STORAGETYPE=local` - 本地存储模式
- `DEPLOY_MODE=STANDALONE` - Standalone 部署模式

## Railway 配置

### 持久化存储

项目已配置 Volume 自动挂载到 `/var/lib/milvus`：

```toml
[[deploy.volumes]]
mountPath = "/var/lib/milvus"
name = "milvus-data"
```

所有数据（向量、索引、元数据、etcd）都会持久化保存。

### 服务变量

其他 Railway 服务可以引用以下变量：

```bash
# 在应用服务的 Variables 中添加
MILVUS_HOST=${{milvus-service.MILVUS_HOST}}
MILVUS_PORT=${{milvus-service.MILVUS_PORT}}

# 手动添加认证信息
MILVUS_ROOT_PASSWORD=YourPassword123!
```

暴露的服务变量：
- `MILVUS_HOST` - 私有域名
- `MILVUS_PORT` - 19530
- `MILVUS_GRPC_PORT` - 19530
- `MILVUS_METRICS_PORT` - 9091
- `MILVUS_ETCD_PORT` - 2379
- `MILVUS_URI` - 完整连接 URI

### 健康检查

- **Railway**: 使用 Docker HEALTHCHECK
- **检查端点**: `http://localhost:9091/healthz`
- **启动等待**: 90秒
- **检查间隔**: 30秒
- **重启策略**: 失败时重启（最多10次）

## 安全建议

1. **设置强密码**
   - 至少 8 个字符
   - 包含大小写字母、数字、特殊字符
   - 不要使用默认密码 `Milvus`

2. **密码管理**
   - 通过 Railway Variables 管理
   - 不要在代码中硬编码
   - 定期更换密码

3. **网络隔离**
   - 使用 Railway Private Network 进行服务间通信
   - 只暴露必要的端口

## 多语言示例

### Python

```python
from pymilvus import connections, Collection, FieldSchema, CollectionSchema, DataType
import os

# 连接
connections.connect(
    alias="default",
    host=os.getenv('MILVUS_HOST'),
    port=os.getenv('MILVUS_PORT', '19530'),
    user="root",
    password=os.getenv('MILVUS_ROOT_PASSWORD')
)

# 创建 Collection
fields = [
    FieldSchema(name="id", dtype=DataType.INT64, is_primary=True, auto_id=True),
    FieldSchema(name="embedding", dtype=DataType.FLOAT_VECTOR, dim=128)
]
schema = CollectionSchema(fields=fields)
collection = Collection(name="my_collection", schema=schema)
```

### Node.js

```javascript
const { MilvusClient } = require('@zilliz/milvus2-sdk-node');

const client = new MilvusClient({
  address: process.env.MILVUS_HOST,
  port: process.env.MILVUS_PORT || '19530',
  username: 'root',
  password: process.env.MILVUS_ROOT_PASSWORD
});
```

### Go

```go
import "github.com/milvus-io/milvus-sdk-go/v2/client"

c, err := client.NewClient(context.Background(), client.Config{
    Address:  fmt.Sprintf("%s:%s", os.Getenv("MILVUS_HOST"), os.Getenv("MILVUS_PORT")),
    Username: "root",
    Password: os.Getenv("MILVUS_ROOT_PASSWORD"),
})
```

## 故障排查

### 查看日志

```bash
# Railway: 在项目页面查看 Logs
# Docker: 
docker logs milvus-standalone
```

### 检查健康状态

```bash
curl http://localhost:9091/healthz
```

### 连接问题

1. **认证失败** (`permission deny`)
   - 检查密码是否正确
   - 确认 `MILVUS_ROOT_PASSWORD` 已设置
   - 查看容器日志确认密码配置

2. **端口无法访问**
   - 确认 Railway 已分配公网域名
   - 检查端口映射（19530）

3. **服务未启动**
   - 查看 Railway 部署日志
   - 检查 Volume 是否正确挂载

## 版本信息

- **Milvus**: v2.4.17
- **部署模式**: Standalone with Embedded etcd
- **存储**: 本地文件系统

## 资源要求

**推荐配置**：
- CPU: 2 核心
- 内存: 4GB
- 存储: 10GB+

**最低配置**：
- CPU: 1 核心
- 内存: 2GB
- 存储: 5GB

## 参考资料

- [Milvus 官方文档](https://milvus.io/docs)
- [Milvus GitHub](https://github.com/milvus-io/milvus)
- [Railway 文档](https://docs.railway.app)
- [Milvus 认证文档](https://milvus.io/docs/authenticate.md)

## License

Apache License 2.0
