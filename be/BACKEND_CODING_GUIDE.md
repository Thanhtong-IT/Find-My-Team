# 📘 Hướng dẫn Code Backend — Dành cho Cursor AI

> File này hướng dẫn Cursor AI (hoặc bất kỳ AI coding assistant nào) cách code backend cho dự án **Find My Team**. Đọc file này trước khi bắt tay vào code bất kỳ module nào.

---

## 📂 Tài liệu liên quan

| File | Vai trò |
|---|---|
| `realtime-discord-architecture-find-my-team.md` | Kiến trúc realtime (nguyên tắc thiết kế) |
| `.cursor/rules/backend.mdc` | Cursor rules (quy tắc code bắt buộc) |
| `.cursor/rules/backend-skills.mdc` | Code patterns & snippets mẫu |
| `be/database/V1__init_schema.sql` | Database schema chuẩn |

**⚠️ Bắt buộc**: Đọc cả 4 file trên trước khi code. Mọi code phải tuân thủ rules và patterns đã định.

---

## 🏗 Thứ tự triển khai

### Phase 1: Project Setup

```
Prompt cho Cursor:
"Khởi tạo Spring Boot 3.x project trong thư mục be/ với:
- Java 21
- Gradle (Kotlin DSL)
- Dependencies: web, data-jpa, data-redis, security, validation, websocket, postgresql, flyway, lombok, springdoc-openapi
- Package: com.findmyteam
- Tham khảo dependencies trong .cursor/rules/backend.mdc §15"
```

Sau khi init project:
1. Copy `be/database/V1__init_schema.sql` → `be/src/main/resources/db/migration/V1__init_schema.sql`
2. Tạo `application.yml` theo mẫu trong backend guide
3. Tạo `docker-compose.yml` cho PostgreSQL + Redis

---

### Phase 2: Common Infrastructure

Tạo theo thứ tự:

```
Prompt 1: "Tạo common/dto/ApiResponse.java — wrapper response chuẩn.
           Tham khảo Pattern 6 trong .cursor/rules/backend-skills.mdc"

Prompt 2: "Tạo common/exception/ — ResourceNotFoundException, BusinessException,
           GlobalExceptionHandler. Tham khảo Pattern 7 trong backend-skills.mdc"

Prompt 3: "Tạo common/event/EventType.java enum và EventPublisher.java.
           Tham khảo Pattern 8 trong backend-skills.mdc.
           Event types: MESSAGE_CREATED, TEAM_MEMBER_JOINED, TEAM_MEMBER_LEFT,
           TEAM_DISBANDED, TEAM_MEMBER_READY, JOIN_REQUEST_CREATED,
           JOIN_REQUEST_ACCEPTED, JOIN_REQUEST_REJECTED, MATCH_CREATED,
           NOTIFICATION_NEW, INVITATION_RECEIVED, COMMUNITY_MEMBER_JOINED,
           TEAM_CREATED, TEAM_REQUEST_MATCHED"

Prompt 4: "Tạo security/ — JwtTokenProvider, JwtAuthenticationFilter,
           UserPrincipal, SecurityConfig.
           - JWT access token 1h, refresh token 7 ngày
           - BCrypt password encoding
           - Permit: /api/auth/**, /swagger-ui/**, /v3/api-docs/**
           - Tất cả endpoint khác cần authenticate"

Prompt 5: "Tạo config/RedisConfig.java, CorsConfig.java, SwaggerConfig.java"
```

---

### Phase 3: Auth Module

```
Prompt: "Tạo module auth/ đầy đủ:
- Entity: dùng bảng users + refresh_tokens trong V1__init_schema.sql
- DTO: RegisterRequest, LoginRequest, AuthResponse
- Service: AuthService — register (hash password, save user, generate tokens),
  login (verify password, generate tokens), refresh, logout
- Controller: AuthController — POST /api/auth/register, /login, /refresh, /logout
- Tuân thủ rules trong backend.mdc:
  - Password hash bằng BCrypt
  - JWT access + refresh token
  - Response wrapper ApiResponse
  - Validation annotations trên DTO"
```

---

### Phase 4: User & Game Modules

```
Prompt: "Tạo module game/:
- Entity: Game — map bảng games trong SQL schema
- Repository: GameRepository
- Service: GameService — getAll, getPopular (dùng view v_popular_games), getById
- Controller: GET /api/games, GET /api/games/popular, GET /api/games/{id}
- Game entity có JSONB fields (ranks, roles) — dùng converter"

Prompt: "Tạo module user/:
- Entity: User, UserGameProfile — map bảng users, user_game_profiles
- DTO: UserProfileResponse (gồm gameInfo, stats, currentTeam, communities
  — tương ứng ProfileModel trong Flutter frontend)
- Service: UserService — getMe, getProfile, updateProfile, addGameProfile
- Controller: GET /api/users/me, GET /api/users/me/profile,
  PUT /api/users/me/profile, POST /api/users/me/game-profile,
  GET /api/users/{id}/profile"
```

---

### Phase 5: Team Module (phức tạp nhất)

```
Prompt: "Tạo module team/ đầy đủ. Đây là module phức tạp nhất.
Tham khảo Pattern 1-5 trong backend-skills.mdc.

Entities (map đúng SQL schema):
- Team, TeamMember, JoinRequest, TeamRequest

Endpoints cần:
- POST /api/teams                              (tạo team)
- GET  /api/teams/my                           (team hiện tại)
- GET  /api/teams/open?gameId=&page=&size=     (đội đang tuyển)
- GET  /api/teams/recruiting?limit=5           (cho trang chủ)
- DELETE /api/teams/{id}                       (giải tán — owner only)
- PUT  /api/teams/{id}/ready                   (toggle sẵn sàng)
- POST /api/teams/{id}/leave                   (rời team)
- POST /api/teams/{id}/join-requests           (gửi yêu cầu)
- GET  /api/teams/{id}/join-requests           (xem danh sách — owner only)
- POST /api/teams/{id}/join-requests/{rid}/accept
- POST /api/teams/{id}/join-requests/{rid}/reject
- POST /api/team-requests                      (đăng yêu cầu tìm đội)

⚠️ QUAN TRỌNG:
- Transaction phải ngắn (tách doXxx private method)
- Publish event SAU commit (không trong @Transactional)
- Events: TEAM_CREATED, TEAM_MEMBER_JOINED, TEAM_MEMBER_LEFT,
  TEAM_DISBANDED, TEAM_MEMBER_READY, JOIN_REQUEST_CREATED,
  JOIN_REQUEST_ACCEPTED, JOIN_REQUEST_REJECTED"
```

---

### Phase 6: Community & Chat

```
Prompt: "Tạo module community/:
- Entities: Community, Channel, CommunityMember — map SQL schema
- Endpoints: GET/POST /api/communities, POST .../join, POST .../leave,
  GET/POST /api/communities/{id}/channels

Tạo module chat/:
- Entities: Message, Conversation, ConversationMember, DirectMessage
- Endpoints:
  GET  /api/communities/{id}/channels/{chId}/messages?page=&size=
  POST /api/communities/{id}/channels/{chId}/messages
  (⚠️ hỗ trợ clientMessageId cho idempotency — tham khảo Pattern 10)
- Publish MESSAGE_CREATED event sau commit
- Pagination default: 20 messages, sort createdAt DESC"
```

---

### Phase 7: Notification & Invitation

```
Prompt: "Tạo module notification/:
- Entity: Notification — map SQL schema
- Types: team_invite, join_request, community_post, chat_message,
  request_accepted, request_rejected, match_created, system
  (tương ứng NotificationType enum trong Flutter frontend)
- Endpoints: GET /api/notifications?type=&page=, PUT .../read,
  PUT /api/notifications/read-all, POST .../accept, POST .../reject,
  GET /api/notifications/unread-count

Tạo module invitation/:
- Entity: Invitation — map SQL schema
- Types: team_invite, play_invite
- Endpoints: POST /api/invitations, GET .../received,
  POST .../{id}/accept, POST .../{id}/reject"
```

---

### Phase 8: Explore & Match

```
Prompt: "Tạo module explore/:
- Không có entity riêng, dùng TeamRepository + UserRepository
- Service: ExploreService — searchTeams, getOnlinePlayers (query users
  có presence:user:{id} trong Redis)
- Endpoints: GET /api/explore/search?q=&type=, GET /api/players/online?game=

Tạo module match/:
- Entities: Swipe, Match — map SQL schema
- Logic: POST /api/swipes — save swipe, check reverse like → tạo match
  (⚠️ constraint chk_match_order: luôn lưu user_a < user_b)
- Publish MATCH_CREATED event khi match
- Endpoints: POST /api/swipes, GET /api/matches"
```

---

### Phase 9: WebSocket Gateway

```
Prompt: "Tạo websocket/ package:
- WebSocketHandler: xử lý connect (auth JWT), disconnect, heartbeat
- EventSubscriber: subscribe Redis Pub/Sub, push event tới đúng client
- PresenceService: quản lý online/offline bằng Redis SET + TTL
  (tham khảo Pattern 9 trong backend-skills.mdc)
- RoomManager: track user thuộc team/channel nào

Khi connect:
1. Validate JWT token từ query param
2. Set presence:user:{userId} = online, TTL 60s
3. Subscribe vào events:user:{userId}
4. Subscribe vào events của teams/channels user thuộc

Heartbeat mỗi 30s:
- Gia hạn TTL presence

Khi disconnect:
- Set TTL ngắn (5s) cho presence, nếu không reconnect → offline
- Publish USER_OFFLINE event

WebSocket message format:
  {op: 'heartbeat|dispatch|resume', t: 'EVENT_TYPE', d: {data}}"
```

---

### Phase 10: Worker Service

```
Prompt: "Tạo worker/ package (có thể nằm trong cùng Spring Boot app hoặc tách service):
- NotificationWorker: subscribe Redis events, tạo notification record,
  gửi push notification cho offline users
- UnreadCountWorker: subscribe MESSAGE_CREATED, update unread_count
  trong conversation_members

Worker chạy bằng @EventListener hoặc Redis MessageListener.
Không block main thread."
```

---

## 🔑 Checklist trước khi code mỗi module

Khi Cursor bắt đầu code một module mới, kiểm tra:

- [ ] Entity map đúng tên bảng + cột trong `V1__init_schema.sql`
- [ ] DTO dùng Java Record + validation annotations
- [ ] Controller return `ApiResponse<T>`, không return entity trực tiếp
- [ ] Service tách `@Transactional` method riêng, publish event **sau** commit
- [ ] Không query DB trong WebSocket handler
- [ ] Không gọi external service (email/push) trong transaction
- [ ] Pagination dùng `Pageable`, default size 10, max 50
- [ ] Error dùng `BusinessException` / `ResourceNotFoundException`
- [ ] Có `@Valid` trên request body
- [ ] Endpoint cần auth dùng `@AuthenticationPrincipal UserPrincipal`

---

## 🧪 Test Plan

Sau mỗi module, test bằng:

```
Prompt: "Tạo integration test cho {Module}Controller:
- Dùng @SpringBootTest + @AutoConfigureMockMvc
- Test happy path + error cases
- Mock authentication bằng @WithMockUser hoặc custom annotation
- Verify response format (ApiResponse wrapper)
- Verify event publishing (mock EventPublisher)"
```

---

## 📋 Quick Reference: Frontend ↔ Backend

```
Flutter Screen              →  Backend API
─────────────────────────────────────────────
SplashScreen                →  (none — client side)
LoginScreen                 →  POST /api/auth/login
RegisterScreen              →  POST /api/auth/register
SetupProfileScreen          →  PUT /api/users/me/profile
                               POST /api/users/me/game-profile
HomeScreen                  →  GET /api/users/me
                               GET /api/games/popular
                               GET /api/teams/recruiting
ExploreScreen               →  GET /api/teams/open
                               GET /api/players/online
GameSelectionScreen         →  GET /api/games
CreateRequestScreen         →  POST /api/team-requests
TeamScreen (Nhóm)           →  POST /api/teams
                               GET /api/teams/my
                               PUT /api/teams/{id}/ready
                               DELETE /api/teams/{id}
TeamScreen (Yêu cầu)       →  GET /api/teams/my/join-requests
                               POST .../accept | .../reject
TeamScreen (Cộng đồng)     →  GET /api/communities
CommunityChatScreen         →  GET/POST .../channels/{chId}/messages
NotificationScreen          →  GET /api/notifications
                               PUT .../read | .../read-all
ProfileScreen               →  GET /api/users/me/profile
```
