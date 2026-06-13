# 📱 Hướng dẫn Code Flutter Frontend — Dành cho Cursor AI

> File này hướng dẫn Cursor AI (hoặc bất kỳ AI coding assistant nào) cách code frontend Flutter cho dự án **Find My Team**. Đọc file này trước khi bắt tay vào code bất kỳ màn hình hay chức năng nào để đảm bảo tính đồng bộ với backend.

---

## 📂 Tài liệu liên quan

| File | Vai trò |
|---|---|
| `realtime-discord-architecture-find-my-team.md` | Kiến trúc realtime (nguyên tắc thiết kế) |
| `be/BACKEND_CODING_GUIDE.md` | Hướng dẫn code backend Spring Boot |
| `.cursor/rules/frontend.mdc` | Cursor rules cho Flutter frontend (quy tắc code bắt buộc) |

**⚠️ Bắt buộc**: Đọc cả 3 file trên trước khi code. Mọi code phải tuân thủ rules và patterns đã định để đồng bộ hoàn toàn với backend Spring Boot.

---

## 🏗 Kiến trúc & Cấu trúc thư mục

Dự án Flutter áp dụng cấu trúc **Clean Architecture + Feature-First** nhằm đảm bảo khả năng mở rộng và dễ bảo trì.

### 📂 Cấu trúc tổng quan của `fe/lib/`

```
fe/lib/
├── main.dart                 # Điểm khởi chạy ứng dụng
├── core/                     # Hạ tầng chung (không phụ thuộc vào feature nào)
│   ├── constants/            # Màu sắc, kích thước, chuỗi, route names
│   ├── network/              # Dio client, interceptors (JWT auth, token refresh)
│   ├── repository/           # Base repository hoặc local storage helper (Secure Storage)
│   ├── utils/                # Helper functions, formatters, validators
│   ├── websocket/            # WebSocket client, heartbeat, reconnect & sync
│   └── events/               # Event bus hoặc event type định nghĩa cho realtime
└── features/                 # Các chức năng nghiệp vụ (Modules)
    ├── auth/                 # Xác thực (Đăng nhập, Đăng ký)
    ├── home/                 # Trang chủ (Danh sách game, Đội tuyển tuyển thành viên)
    ├── explore/              # Khám phá (Tìm đội open, quét người chơi online, swipe/match)
    ├── team/                 # Quản lý nhóm (Tạo nhóm, yêu cầu tham gia, sẵn sàng)
    ├── community/            # Cộng đồng (Kênh chat, danh sách kênh)
    ├── notification/         # Thông báo realtime (Lời mời, chấp nhận yêu cầu)
    └── profile/              # Hồ sơ người dùng (Thông tin cá nhân, profile game)
```

### 📂 Cấu trúc chi tiết của một Feature (ví dụ: `auth`)

Trong mỗi feature thuộc `features/`, chia nhỏ theo các lớp để đảm bảo tách biệt UI và Logic:

```
features/auth/
├── screens/                  # Giao diện màn hình chính (Widgets dạng Screen)
│   ├── login_screen.dart
│   └── register_screen.dart
├── widgets/                  # Các widget con tái sử dụng riêng cho feature này
│   └── auth_text_field.dart
├── bloc/                     # Quản lý trạng thái (Bloc hoặc Cubit)
│   ├── auth_bloc.dart
│   ├── auth_event.dart
│   └── auth_state.dart
├── models/                   # Data models (chuyển đổi JSON ↔ Dart Object)
│   ├── user_model.dart
│   └── auth_tokens.dart
└── services/                 # Gọi API trực tiếp hoặc tương tác local storage
    └── auth_api_service.dart
```

---

## 🏗 Thứ tự triển khai (10 Phases tương thích Backend)

### Phase 1: Project Setup & Dependencies

Cài đặt các thư viện cần thiết vào `pubspec.yaml`:
- **State Management**: `flutter_bloc`
- **Network**: `dio` (kết nối REST API, hỗ trợ interceptors)
- **Local Storage**: `flutter_secure_storage` (lưu trữ an toàn JWT tokens)
- **WebSocket**: `web_socket_channel` (kết nối realtime gateway)
- **Service Locator**: `get_it` (dependency injection)
- **JSON Serialization**: `json_annotation`, `json_serializable` (dùng cùng `build_runner` để generate model)
- **Utility**: `uuid` (sinh clientMessageId cho chat và idempotency)

---

### Phase 2: Common Infrastructure

Tạo hạ tầng dùng chung trong thư mục `core/`:

```
Prompt 1: "Tạo core/network/api_response.dart — Lớp wrapper response tương ứng với ApiResponse của backend.
           Có cấu trúc: class ApiResponse<T> { final bool success; final T? data; final String? message; }"

Prompt 2: "Tạo core/network/dio_client.dart và auth_interceptor.dart:
           - Cấu hình base URL, timeout cho Dio.
           - AuthInterceptor: tự động lấy access token từ FlutterSecureStorage để đính kèm vào Authorization header.
           - Xử lý refresh token rotation: Khi nhận mã lỗi 401, tự động gọi API POST /api/auth/refresh để lấy access token mới, cập nhật storage và retry request ban đầu. Nếu refresh token hết hạn, xóa storage và redirect về LoginScreen."

Prompt 3: "Tạo core/websocket/websocket_client.dart:
           - Quản lý kết nối WebSocket đến ws://<host>/ws?token=<jwt>.
           - Xử lý Heartbeat: Tự động gửi message '{ \"op\": \"heartbeat\" }' mỗi 30 giây để duy trì trạng thái presence online trên backend.
           - Tự động Reconnect sau 5s khi mất kết nối.
           - Lưu lastEventId để gửi lệnh resume '{ \"op\": \"resume\", \"d\": { \"lastEventId\": \"xxx\" } }' khi kết nối lại nhằm đồng bộ event bị lỡ."
```

---

### Phase 3: Auth Module (Integration)

Tích hợp chức năng đăng nhập, đăng ký và thiết lập profile ban đầu:

```
Prompt: "Tạo module auth/ đầy đủ logic kết nối API:
- Định nghĩa model: UserModel, AuthTokens. Xử lý convert JSON camelCase từ snake_case của backend.
- Tạo AuthApiService: POST /api/auth/register, POST /api/auth/login. Sau khi thành công, lưu access token và refresh token vào FlutterSecureStorage.
- Tạo AuthBloc/Cubit quản lý trạng thái login: AuthInitial, AuthLoading, Authenticated, Unauthenticated, AuthError.
- Cập nhật LoginScreen và RegisterScreen để dùng AuthBloc, hiển thị loading indicator và SnackBar báo lỗi khi thất bại."
```

---

### Phase 4: User & Game Modules

Tải danh sách game phổ biến và cấu hình hồ sơ game của người dùng:

```
Prompt: "Tạo model GameModel và UserProfileModel tương thích JSON backend.
- GameModel: chứa id, name, ranks (List<String>), roles (List<String>).
- UserProfileModel: chứa thông tin cá nhân và danh sách profile game của họ (UserGameProfile).
- Tạo UserService:
  - GET /api/games/popular (game trang chủ)
  - GET /api/users/me/profile (lấy hồ sơ cá nhân)
  - PUT /api/users/me/profile (cập nhật thông tin)
  - POST /api/users/me/game-profile (thêm profile game như Rank, Role)
- Tạo ProfileBloc quản lý việc load và update profile."
```

---

### Phase 5: Team Module (Quản lý Nhóm)

Đây là chức năng quan trọng nhất của client, cần quản lý trạng thái nhóm hiện tại sát sao:

```
Prompt: "Tạo module team/ kết nối đầy đủ các API backend:
- Models: TeamModel, TeamMemberModel, JoinRequestModel.
- Endpoints tích hợp:
  - POST /api/teams (Tạo nhóm)
  - GET /api/teams/my (Lấy thông tin nhóm hiện tại)
  - GET /api/teams/open (Tìm kiếm nhóm đang tuyển thành viên)
  - PUT /api/teams/{id}/ready (Sẵn sàng)
  - POST /api/teams/{id}/leave (Rời nhóm)
  - DELETE /api/teams/{id} (Giải tán nhóm - chỉ Owner)
  - GET /api/teams/my/join-requests (Lấy danh sách yêu cầu tham gia)
  - POST /api/teams/my/join-requests/{rid}/accept (Chấp nhận thành viên)
- Tạo TeamBloc để quản lý các action trên, đồng bộ dữ liệu nhóm hiển thị trên giao diện TeamScreen."
```

---

### Phase 6: Community & Chat (Realtime Chat)

Áp dụng kỹ thuật **Optimistic UI** và **Deduplication** để chat mượt mà giống Discord.

```
Prompt: "Tạo module community/ và chat/:
- Models: CommunityModel, ChannelModel, MessageModel.
- Endpoints:
  - GET /api/communities (Lấy danh sách cộng đồng)
  - GET /api/communities/{id}/channels/{chId}/messages?page=&size= (Load tin nhắn cũ)
  - POST /api/communities/{id}/channels/{chId}/messages (Gửi tin nhắn)
- Xử lý Optimistic UI khi gửi tin nhắn:
  1. Khi user bấm Send, sinh clientMessageId dạng UUID, tạo một MessageModel tạm thời có trạng thái 'sending', thêm ngay lập tức vào danh sách tin nhắn hiển thị trên UI.
  2. Gọi API POST gửi tin nhắn kèm clientMessageId.
  3. Nếu thành công (API trả về tin nhắn có ID thật), cập nhật status của tin nhắn đó thành 'sent'.
  4. Nếu lỗi, cập nhật status thành 'failed' và hiển thị nút gửi lại (retry).
- Xử lý Realtime: Lắng nghe tin nhắn từ WebSocketClient qua stream. Khi nhận được event MESSAGE_CREATED:
  - Check nếu clientMessageId trùng với tin nhắn đang hiển thị trên UI ở trạng thái 'sending' -> Cập nhật ID thật và status thành 'sent'.
  - Nếu là tin nhắn mới từ người khác -> Thêm vào list tin nhắn."
```

---

### Phase 7: Notification & Invitation (Realtime Notification)

Lắng nghe các thông báo realtime đẩy từ server qua WebSocket.

```
Prompt: "Tạo module notification/ và invitation/:
- Models: NotificationModel, InvitationModel.
- Endpoints:
  - GET /api/notifications (Xem danh sách thông báo)
  - PUT /api/notifications/read-all (Đánh dấu đã đọc hết)
  - POST /api/invitations (Gửi lời mời chơi/vào nhóm)
- Realtime integration:
  - Đăng ký lắng nghe event NOTIFICATION_NEW, INVITATION_RECEIVED từ WebSocketClient.
  - Khi nhận event, tăng số đếm thông báo chưa đọc trên badge UI và hiển thị Banner thông báo đẩy nhanh trong ứng dụng (In-app notification toast)."
```

---

### Phase 8: Explore & Match (Tìm kiếm & Quét Đồng Đội)

Tích hợp tính năng vuốt chọn (swipe) đồng đội và hiển thị trạng thái online.

```
Prompt: "Tạo module explore/:
- Endpoints:
  - GET /api/explore/search?q=&type= (Tìm kiếm đội hoặc người chơi)
  - GET /api/players/online?game= (Lấy danh sách người chơi online từ Redis presence)
  - POST /api/swipes (Gửi hành động like/dislike)
  - GET /api/matches (Lấy danh sách các cặp đấu đã match)
- Realtime integration:
  - Lắng nghe event MATCH_CREATED từ WebSocketClient. Khi nhận được event, hiển thị ngay màn hình pop-up Match thành công ('It's a Match!') giống Discord/Tinder."
```

---

### Phase 9: Sync & Auto-Reconnection (Mất mạng và kết nối lại)

```
Prompt: "Bổ sung ConnectivityBloc lắng nghe trạng thái mạng (cellular/wifi):
- Khi mất kết nối: Hiển thị thanh thông báo 'Mất kết nối mạng. Đang thử lại...' màu vàng phía trên ứng dụng.
- Khi có mạng lại: 
  1. Gọi WebSocketClient thực hiện reconnect và gửi event resume.
  2. Refresh lại danh sách tin nhắn hiện tại bằng cách gọi API tin nhắn mới nhất để tránh bị sót tin nhắn trong thời gian offline.
  3. Refresh lại data màn hình hiện tại (Team, Notifications)."
```

---

## 🔑 Checklist trước khi code mỗi module Flutter

Khi Cursor bắt đầu code một module mới hoặc màn hình mới, kiểm tra các điểm sau:

- [ ] **Model mapping**: Model phải sử dụng đúng camelCase cho Dart properties và snake_case cho JSON keys từ Backend. Sử dụng decorator `@JsonKey(name: 'backend_field_name')`.
- [ ] **Tách biệt Logic & UI**: Không gọi API trực tiếp trong UI (Screen/Widget). Tất cả các API call và logic nghiệp vụ phải đi qua `Bloc` hoặc `Cubit`.
- [ ] **Trạng thái Loading & Error**: Mọi API call đều phải xử lý trạng thái Loading (hiển thị indicator) và Error (báo lỗi qua SnackBar hoặc empty state, tránh màn hình crash).
- [ ] **Optimistic UI**: Ở các phần gửi tin nhắn hoặc thả cảm xúc, UI phải cập nhật trước và đồng bộ trạng thái lưu từ API sau.
- [ ] **Idempotency Key**: Gửi tin nhắn chat bắt buộc phải sinh ngẫu nhiên `clientMessageId` bằng thư viện `uuid` để tránh tin nhắn bị nhân đôi khi bị lag mạng.
- [ ] **Dispose Controllers**: Tất cả `TextEditingController`, `ScrollController`, `StreamController`, `StreamSubscription` phải được `dispose()` để tránh rò rỉ bộ nhớ (memory leaks).
- [ ] **Responsive Design**: Sử dụng `MediaQuery` hoặc class helper `AppSizes` để thiết kế giao diện tương thích với nhiều kích thước màn hình điện thoại khác nhau.
- [ ] **JWT Auth**: Mọi request đến API cần xác thực phải đi qua instance `Dio` có gắn `AuthInterceptor`, không dùng instance Dio trần.

---

## 🧪 Test Plan cho Frontend

Sau khi hoàn thành code một module, yêu cầu viết các test sau:

```
Prompt: "Tạo unit test cho {Feature}Bloc:
- Mock API service / repository sử dụng Mocktail hoặc Mockito.
- Viết test case kiểm tra:
  - Trạng thái khởi tạo (Initial State).
  - Trạng thái chuyển đổi khi Event được add: Bloc phát ra [Loading, Success] khi gọi API thành công.
  - Trạng thái chuyển đổi khi Event được add: Bloc phát ra [Loading, Error] khi API fail."
```

---

## 📋 Bảng tham chiếu nhanh: Giao diện Flutter ↔ API Backend

| Flutter Screen (Màn hình) | File code Dart | REST API Backend | Realtime WebSocket Event |
|---|---|---|---|
| **LoginScreen** | `lib/features/auth/screens/login_screen.dart` | `POST /api/auth/login` | (Không có) |
| **RegisterScreen** | `lib/features/auth/screens/register_screen.dart` | `POST /api/auth/register` | (Không có) |
| **SetupProfileScreen** | `lib/features/auth/screens/setup_profile_screen.dart` | `PUT /api/users/me/profile`, `POST /api/users/me/game-profile` | (Không có) |
| **HomeScreen** | `lib/features/home/screens/home_screen.dart` | `GET /api/games/popular`, `GET /api/teams/recruiting` | (Không có) |
| **ExploreScreen** | `lib/features/explore/screens/explore_screen.dart` | `GET /api/teams/open`, `GET /api/players/online` | Lắng nghe: `USER_ONLINE`, `USER_OFFLINE` |
| **SwipeMatchScreen** | `lib/features/explore/screens/swipe_match_screen.dart` | `POST /api/swipes`, `GET /api/matches` | Lắng nghe: `MATCH_CREATED` |
| **TeamScreen (Nhóm hiện tại)**| `lib/features/team/screens/team_screen.dart` | `GET /api/teams/my`, `PUT /api/teams/{id}/ready`, `POST /api/teams/{id}/leave` | Lắng nghe: `TEAM_MEMBER_READY`, `TEAM_MEMBER_JOINED`, `TEAM_MEMBER_LEFT` |
| **TeamScreen (Danh sách yêu cầu)**| `lib/features/team/screens/team_requests_tab.dart` | `GET /api/teams/my/join-requests`, `POST .../{rid}/accept`, `POST .../{rid}/reject` | Lắng nghe: `JOIN_REQUEST_CREATED` |
| **CommunityChatScreen** | `lib/features/community/screens/chat_screen.dart` | `GET /api/communities/{id}/channels/{chId}/messages`, `POST /api/communities/{id}/channels/{chId}/messages` | Lắng nghe: `MESSAGE_CREATED`<br>Gửi: `TYPING_START` (qua WS) |
| **NotificationScreen** | `lib/features/notification/screens/notification_screen.dart` | `GET /api/notifications`, `PUT /api/notifications/read-all` | Lắng nghe: `NOTIFICATION_NEW`, `INVITATION_RECEIVED` |
| **ProfileScreen** | `lib/features/profile/screens/profile_screen.dart` | `GET /api/users/me/profile`, `PUT /api/users/me/profile` | (Không có) |
