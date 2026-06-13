# Find My Team - Backend

Backend API cho nền tảng **Find My Team** - Kết nối người chơi game.

## Tech Stack

- **Java 21**
- **Spring Boot 3.3**
- **PostgreSQL 16** - Database chính
- **Redis** - Pub/Sub, Presence, Cache
- **Flyway** - Database migration
- **JWT** - Authentication

## Cấu trúc thư mục

```
be/
├── src/main/java/com/findmyteam/
│   ├── config/           # Redis, CORS, Swagger, Security configs
│   ├── security/         # JWT provider, filter, UserPrincipal
│   ├── common/           # ApiResponse, exceptions, events
│   └── modules/
│       ├── auth/         # Register, login, refresh token
│       ├── user/         # User profile, game profiles
│       ├── game/         # Game listing
│       ├── team/         # Team management
│       ├── community/    # Community & channels
│       ├── chat/         # Messages
│       ├── notification/  # Notifications
│       ├── explore/      # Search & discovery
│       ├── invitation/   # Team invites
│       └── match/        # Swipe & match
├── src/main/resources/
│   ├── application.yml
│   └── db/migration/     # Flyway migrations
├── build.gradle.kts
└── docker-compose.yml
```

## Cách chạy

### 1. Khởi động Database (Docker)

```bash
cd be
docker-compose up -d
```

### 2. Build & Run

```bash
# Sử dụng Gradle wrapper
./gradlew bootRun

# Hoặc build JAR
./gradlew bootJar
java -jar build/libs/find-my-team-backend.jar
```

### 3. Truy cập API

- API Base URL: `http://localhost:8080/api`
- Swagger UI: `http://localhost:8080/swagger-ui.html`
- API Docs: `http://localhost:8080/v3/api-docs`

## API Endpoints

### Authentication
| Method | Endpoint | Mô tả |
|--------|----------|-------|
| POST | `/api/auth/register` | Đăng ký |
| POST | `/api/auth/login` | Đăng nhập |
| POST | `/api/auth/refresh` | Refresh token |
| POST | `/api/auth/logout` | Đăng xuất |

### Games
| Method | Endpoint | Mô tả |
|--------|----------|-------|
| GET | `/api/games` | Danh sách games |
| GET | `/api/games/popular` | Games phổ biến |
| GET | `/api/games/{id}` | Chi tiết game |

### Teams
| Method | Endpoint | Mô tả |
|--------|----------|-------|
| POST | `/api/teams` | Tạo team |
| GET | `/api/teams/my` | Team của tôi |
| GET | `/api/teams/open` | Teams đang tuyển |
| DELETE | `/api/teams/{id}` | Giải tán team |
| PUT | `/api/teams/{id}/ready` | Toggle ready |

Xem thêm trong Swagger UI.

## Kiến trúc Realtime

Hệ thống sử dụng kiến trúc **Event-driven** (Discord-style):

1. **API Service** xử lý business logic → ghi DB → commit
2. **EventPublisher** publish event vào Redis Pub/Sub
3. **WebSocket Gateway** nhận event → push tới client
4. **Worker** xử lý notification, email (async)

Xem chi tiết: `realtime-discord-architecture-find-my-team.md`

## Development

### Quy tắc code

1. **Transaction ngắn** - Không emit WebSocket trong transaction
2. **Event sau commit** - Publish event sau khi DB commit xong
3. **DTO pattern** - Dùng Java Record + validation annotations
4. **Response wrapper** - Mọi API trả về `ApiResponse<T>`

Xem: `.cursor/rules/backend.mdc`

### Cài đặt pre-commit (tùy chọn)

```bash
# Cài đặt pre-commit hooks
pre-commit install
```

## Environment Variables

| Variable | Default | Mô tả |
|----------|---------|-------|
| DB_HOST | localhost | PostgreSQL host |
| DB_PORT | 5432 | PostgreSQL port |
| DB_NAME | findmyteam | Database name |
| DB_USERNAME | postgres | Database user |
| DB_PASSWORD | postgres | Database password |
| REDIS_HOST | localhost | Redis host |
| REDIS_PORT | 6379 | Redis port |
| JWT_SECRET | ... | JWT signing key (thay đổi production!) |

## License

MIT
