# Milvus Railway Deployment

这是一个可以在 Railway 上部署的 Milvus Standalone 模式向量数据库项目。

## 特性

- 🚀 使用 Milvus Standalone 模式（内嵌 etcd）
- 📦 本地存储（适合开发和测试）
- 💾 配置 Railway Volume 持久化存储，防止数据丢失
- 🔧 可通过 `user.yaml` 自定义配置
- 🏥 内置健康检查

## 快速开始

### 在 Railway 上部署

1. Fork 此仓库
2. 在 [Railway](https://railway.app) 创建新项目
3. 连接你的 GitHub 仓库
4. Railway 会自动检测 `railway.toml` 和 Dockerfile 并开始部署
5. **重要：Volume 会自动创建**
   - `railway.toml` 已配置将 `/var/lib/milvus` 挂载到持久化 Volume
   - 这将保存所有 Milvus 数据和 etcd 数据，防止容器重启时数据丢失
6. 部署完成后，Railway 会分配一个公网地址

### 本地运行

```bash
# 构建镜像
docker build -t milvus-railway .

# 运行容器
docker run -d \
  --name milvus-standalone \
  -p 19530:19530 \
  -p 9091:9091 \
  -p 2379:2379 \
  -v $(pwd)/volumes/milvus:/var/lib/milvus \
  milvus-railway
```

### 连接到 Milvus

```python
from pymilvus import connections

# 连接到 Milvus
connections.connect(
    alias="default",
    host="your-railway-url.railway.app",  # 或 localhost
    port="19530"
)
```

## 端口说明

- **19530**: Milvus gRPC 服务端口
  - 主要连接端口，客户端通过此端口连接
  - **Railway 对外暴露的端口**（通过 `PORT=19530` 设置）
  - 公网访问：`your-app.railway.app:19530`
- **9091**: Milvus Metrics 端口
  - 健康检查端点：`/healthz`
  - 监控指标端点：`/metrics`
  - **仅容器内部使用**，不对外暴露
- **2379**: etcd 客户端端口
  - 内嵌 etcd 的客户端接口
  - **仅容器内部使用**，不对外暴露

## 配置说明

### embedEtcd.yaml

内嵌 etcd 的配置文件，包含：
- 监听地址
- 后端存储大小限制（4GB）
- 自动压缩设置

### user.yaml

用户自定义配置文件，可以覆盖 Milvus 的默认配置。

示例配置：

```yaml
# 日志级别
log:
  level: info

# 代理配置
proxy:
  port: 19530
  
# 数据协调器配置
dataCoord:
  segment:
    maxSize: 512
```

## Railway 特别说明

### 环境变量

Railway 会自动设置以下环境变量（已在配置中设定）：

**Dockerfile 中配置的环境变量：**
- `ETCD_USE_EMBED=true`: 使用内嵌 etcd
- `ETCD_DATA_DIR=/var/lib/milvus/etcd`: etcd 数据目录
- `COMMON_STORAGETYPE=local`: 使用本地存储
- `DEPLOY_MODE=STANDALONE`: Standalone 部署模式

**railway.toml 中配置的环境变量：**
- `PORT=19530`: Railway 对外暴露的端口（Milvus gRPC 主端口）
  - 客户端应通过此端口连接 Milvus
  - Railway 会将此端口映射到公网地址

### 服务变量（Service Variables）

项目已配置以下服务变量，**其他 Railway 服务可以直接引用**：

```bash
MILVUS_HOST              # Milvus 主机地址（私有网络）
MILVUS_PORT              # Milvus gRPC 端口 (19530)
MILVUS_GRPC_PORT         # Milvus gRPC 端口 (19530)
MILVUS_METRICS_PORT      # Milvus Metrics 端口 (9091)
MILVUS_ETCD_PORT         # etcd 端口 (2379)
MILVUS_URI               # 完整的 Milvus 连接 URI
```

**在其他 Railway 服务中使用：**

在其他服务的环境变量中，可以这样引用：

```bash
# 方式1: 引用单个变量
MILVUS_HOST=${{milvus-service.MILVUS_HOST}}
MILVUS_PORT=${{milvus-service.MILVUS_PORT}}

# 方式2: 直接使用 URI
MILVUS_URI=${{milvus-service.MILVUS_URI}}
```

**代码中使用示例：**

```python
# Python
import os
from pymilvus import connections

milvus_host = os.getenv('MILVUS_HOST')
milvus_port = os.getenv('MILVUS_PORT', '19530')

connections.connect(
    alias="default",
    host=milvus_host,
    port=milvus_port
)
```

```javascript
// Node.js
const { MilvusClient } = require('@zilliz/milvus2-sdk-node');

const client = new MilvusClient({
  address: process.env.MILVUS_HOST,
  port: process.env.MILVUS_PORT || '19530'
});
```

```go
// Go
import "github.com/milvus-io/milvus-sdk-go/v2/client"

milvusAddr := fmt.Sprintf("%s:%s", 
    os.Getenv("MILVUS_HOST"),
    os.Getenv("MILVUS_PORT"))

c, err := client.NewGrpcClient(context.Background(), milvusAddr)
```

### 持久化存储

**已自动配置 Volume！** 项目中的 `railway.toml` 文件已经配置了 Volume 挂载：

```toml
[[deploy.volumes]]
mountPath = "/var/lib/milvus"
name = "milvus-data"
```

这将自动：
- ✅ 创建名为 `milvus-data` 的持久化 Volume
- ✅ 挂载到容器的 `/var/lib/milvus` 目录
- ✅ 保存所有 Milvus 数据（向量数据、索引、元数据）
- ✅ 保存 etcd 数据（集群配置、schema 信息）
- ✅ 容器重启或重新部署时数据不会丢失

**无需手动配置**，Railway 会在首次部署时自动创建并挂载 Volume。

您可以在 Railway 项目的 "Volumes" 标签页中查看和管理 Volume：
- 查看存储使用情况
- 下载备份
- 删除 Volume（谨慎操作）

### 健康检查

**Railway 健康检查策略：**
- Railway 禁用了内置的 HTTP 健康检查（因为 Milvus 在不同端口提供健康检查）
- 使用 **Docker 容器的 HEALTHCHECK** 指令进行健康监控
- Railway 会监控容器状态，如果不健康会根据重启策略重启

**Docker 容器健康检查配置：**
- **检查命令**: `curl -f http://localhost:9091/healthz`
- **检查间隔**: 30秒
- **启动等待时间**: 90秒（Milvus 启动需要时间）
- **超时时间**: 20秒
- **重试次数**: 3次

**Railway 重启策略：**
- **策略**: `ON_FAILURE`（失败时重启）
- **最大重试**: 10次

**端口说明：**
- **19530**: 对外暴露的 gRPC 端口（通过 `PORT` 环境变量设置）
- **9091**: 内部健康检查端口（不对外暴露）
- **2379**: etcd 端口（不对外暴露）

## 版本信息

- Milvus: v2.4.17
- 部署模式: Standalone with Embedded etcd

## 资源要求

推荐配置：
- CPU: 2 核心
- 内存: 4GB
- 存储: 10GB+

## 故障排查

### 查看日志

```bash
docker logs milvus-standalone
```

### 检查健康状态

```bash
curl http://localhost:9091/healthz
```

### 连接问题

1. 确保端口 19530 已开放
2. 检查防火墙设置
3. 验证网络连接

## 参考资料

- [Milvus 官方文档](https://milvus.io/docs)
- [Milvus GitHub](https://github.com/milvus-io/milvus)
- [Railway 文档](https://docs.railway.app)

## License

Apache License 2.0
