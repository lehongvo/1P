# LOTUS O2O System - Phoenix OMS & Commerce Engine

Hệ thống giám sát O2O (Online-to-Offline) của LOTUS với Phoenix OMS và Phoenix Commerce Engine.

## 🏗️ Kiến trúc hệ thống

```
┌─────────────────┐    ┌─────────────────────┐    ┌─────────────────┐
│   Phoenix OMS   │───▶│ Phoenix Commerce    │───▶│   PostgreSQL    │
│   (Port 3001)   │    │ Engine (Port 3002)  │    │   Database      │
└─────────────────┘    └─────────────────────┘    └─────────────────┘
```

## 📋 Tính năng

### Phoenix OMS (Order Management System)
- ✅ Quản lý đơn hàng với các trạng thái đầy đủ
- ✅ Tạo mock data với 10 trạng thái khác nhau
- ✅ API endpoints cho CRUD operations
- ✅ Theo dõi lịch sử thay đổi trạng thái
- ✅ Health check và monitoring

### Phoenix Commerce Engine
- ✅ Xử lý business logic validation
- ✅ Kiểm tra inventory, pricing, customer eligibility
- ✅ Tích hợp với Phoenix OMS
- ✅ Monitoring events và processing stats
- ✅ Cron job tự động xử lý đơn hàng (30s)
- ✅ Simulate failures và delays

### Database Schema
- ✅ Orders table với đầy đủ thông tin
- ✅ Order items và status history
- ✅ Commerce processing tracking
- ✅ System monitoring events

## 🚀 Cách chạy hệ thống (1 package.json ở root)

### 1. Cài đặt dependencies (root duy nhất)

```bash
# Dùng yarn (khuyến nghị)
yarn install

# Hoặc dùng npm
npm install
```

### 2. Chạy Development mode (từ root)

```bash
# Terminal 1: Chạy Postgres bằng docker-compose
docker-compose up postgres -d

# Terminal 2: Chạy song song OMS và Commerce từ root
yarn dev
# hoặc: npm run dev
```

- OMS dev: ts-node-dev chạy `phoenix-oms/src/index.ts` (Port 3001)
- Commerce dev: ts-node-dev chạy `phoenix-commerce/src/index.ts` (Port 3002)

### 3. Build và Start (từ root)

```bash
# Build TypeScript cho cả 2 services
yarn build
# hoặc: npm run build

# Start từng service (chạy JS đã build)
yarn start:oms
yarn start:commerce
# hoặc: npm run start:oms && npm run start:commerce
```

### 4. Chạy với Docker (khuyến nghị cho demo nhanh)

```bash
# Build & up tất cả services: Postgres, OMS, Commerce
docker-compose up -d --build

# Xem logs
docker-compose logs -f

# Dừng services
docker-compose down
```

## 📊 API Endpoints

### Phoenix OMS (http://localhost:3001)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/health` | Health check |
| GET | `/api/v1/orders` | Lấy danh sách đơn hàng |
| POST | `/api/v1/orders` | Tạo đơn hàng mới |
| GET | `/api/v1/orders/:orderId` | Lấy chi tiết đơn hàng |
| PUT | `/api/v1/orders/:orderId/status` | Cập nhật trạng thái đơn hàng |
| GET | `/api/v1/orders/:orderId/items` | Lấy items của đơn hàng |
| GET | `/api/v1/orders/:orderId/history` | Lấy lịch sử trạng thái |
| POST | `/api/v1/seed-mock-data` | Tạo mock data |

### Phoenix Commerce Engine (http://localhost:3002)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/health` | Health check |
| POST | `/api/v1/process/:orderId` | Xử lý đơn hàng |
| GET | `/api/v1/processing-history` | Lịch sử xử lý |
| GET | `/api/v1/monitoring-events` | Events monitoring |
| GET | `/api/v1/processing-stats` | Thống kê xử lý |
| POST | `/api/v1/simulate-processing` | Simulate xử lý |

## 📈 Trạng thái đơn hàng (Order Status)

| Status | Mapping | Mô tả |
|--------|---------|-------|
| PENDING | Delayed | Đơn hàng mới, chờ xử lý |
| PENDING_PAYMENT | Delayed | Chờ xác nhận thanh toán |
| PROCESSING | Delayed | Đang xử lý |
| COMPLETE | Success | Hoàn thành thành công |
| CLOSED | Success | Đã đóng, hoàn tất |
| CANCELED | Failed | Đã hủy |
| HOLDED | Delayed | Tạm giữ |
| PAYMENT_REVIEW | Delayed | Đang review thanh toán |
| FRAUD | Failed | Nghi ngờ gian lận |
| SHIPPING | Delayed | Đang giao hàng |

## 🧪 Test hệ thống

### 1. Tạo mock data

```bash
curl -X POST http://localhost:3001/api/v1/seed-mock-data
```

### 2. Xem danh sách đơn hàng

```bash
curl http://localhost:3001/api/v1/orders?limit=10
```

### 3. Xử lý đơn hàng

```bash
curl -X POST http://localhost:3002/api/v1/process/ORD-1234567890-1
```

### 4. Xem thống kê

```bash
curl http://localhost:3002/api/v1/processing-stats
curl http://localhost:3002/api/v1/monitoring-events
```

## 🔧 Cấu hình

Environment Variables dùng chung (qua docker-compose hoặc local shell):

```bash
# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=lotus_o2o
DB_USER=lotus_user
DB_PASSWORD=lotus_password

# Services
PORT (OMS)=3001
PORT (Commerce)=3002
OMS_API_URL=http://localhost:3001
```

## 📊 Monitoring

- OMS → Commerce → Postgres: mọi event được ghi vào `system_monitoring`
- Thống kê thời gian xử lý và trạng thái tại endpoints Commerce

## 🛠️ Development

```
lotus-o2o-system/
├── phoenix-oms/
│   └── src/, tsconfig.json, Dockerfile
├── phoenix-commerce/
│   └── src/, tsconfig.json, Dockerfile
├── database/init.sql
├── docker-compose.yml
├── package.json (root duy nhất)
├── yarn.lock (root duy nhất)
└── scripts/
```

## 📝 License

MIT License - Xem file LICENSE để biết thêm chi tiết.
