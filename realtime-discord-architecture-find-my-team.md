# Thiết kế hệ thống Realtime mượt kiểu Discord cho nền tảng Find My Team

## 1. Bối cảnh vấn đề

Nền tảng **Find My Team** cần realtime cho các chức năng như:

- Chat giữa người dùng
- Thông báo khi có match
- Trạng thái online/offline
- Typing indicator
- Invite vào team
- Cập nhật trạng thái tuyển thành viên
- Notification realtime

Hiện tại nếu hệ thống dùng **WebSocket kết hợp trực tiếp với transaction database**, API có thể bị chậm vì mỗi request phải làm quá nhiều việc trong cùng một luồng xử lý.

Ví dụ luồng dễ gây lag:

```text
Client gửi request
 -> API mở transaction
 -> xử lý logic
 -> ghi database
 -> gửi WebSocket
 -> chờ broadcast xong
 -> commit transaction
 -> trả response
```

Cách này có vấn đề vì WebSocket bị dính vào transaction. Nếu database chậm, network chậm, hoặc broadcast tới nhiều user, toàn bộ API sẽ bị kéo chậm theo.

---

## 2. Discord làm realtime mượt nhờ đâu?

Discord không mượt chỉ vì dùng WebSocket. Điểm quan trọng là Discord tách các phần của hệ thống thành nhiều lớp khác nhau:

```text
Client
 -> Realtime Gateway
 -> Event Router / Pub/Sub
 -> Storage / Search / Notification / Analytics
```

Các bài kỹ thuật của Discord cho thấy họ dùng:

| Thành phần | Công nghệ / hướng tiếp cận | Vai trò |
|---|---|---|
| Realtime Gateway | Elixir / Erlang VM | Giữ nhiều kết nối WebSocket, xử lý event realtime |
| API chính | Python | Xử lý API và business logic |
| Phần cần hiệu năng cao | Rust | Tối ưu các xử lý nóng |
| Message storage | ScyllaDB | Lưu lượng tin nhắn cực lớn |
| Search | Elasticsearch / service riêng | Tìm kiếm tin nhắn |
| Voice / Video | WebRTC / hạ tầng riêng | Realtime media |

Bài học chính không phải là phải dùng đúng công nghệ của Discord, mà là phải học cách họ **tách realtime khỏi transaction nặng**.

---

## 3. Nguyên nhân WebSocket + Transaction làm hệ thống chậm

### 3.1. Transaction bị giữ quá lâu

Transaction database chỉ nên dùng trong thời gian ngắn. Nếu trong transaction có thêm thao tác gửi WebSocket, gọi service khác, gửi email, push notification hoặc xử lý AI thì thời gian giữ lock sẽ tăng.

Ví dụ không tốt:

```text
BEGIN TRANSACTION
 -> insert message
 -> update unread count
 -> send websocket event
 -> send notification
 -> update team state
COMMIT
```

Vấn đề:

- Transaction lâu hơn
- Dễ lock bảng hoặc row
- API response chậm
- Khi WebSocket lỗi có thể làm rollback logic chính
- Khó scale khi số lượng user tăng

---

### 3.2. WebSocket handler làm quá nhiều việc

WebSocket Gateway chỉ nên xử lý realtime nhẹ, ví dụ:

- Xác thực connection
- Nhận event
- Kiểm tra user thuộc room/channel/team nào
- Gửi event tới đúng user
- Heartbeat / ping-pong
- Reconnect / resume

Không nên để WebSocket handler làm:

- Query database phức tạp
- Join nhiều bảng
- Gọi AI
- Gửi email
- Upload file
- Xử lý payment
- Tạo báo cáo
- Index search

---

### 3.3. Broadcast sai phạm vi

Nếu mỗi event đều broadcast quá rộng, hệ thống sẽ lag.

Không tốt:

```text
Có message mới -> gửi cho toàn bộ user online
```

Tốt hơn:

```text
Có message mới trong channel A
 -> chỉ gửi cho member đang online của channel A
```

Realtime phải được route theo phạm vi nhỏ:

- user
- room
- team
- channel
- conversation
- recruitment post

---

## 4. Kiến trúc đề xuất cho Find My Team

### 4.1. Kiến trúc tổng quan

```text
Flutter / Web Client
        |
        | REST API
        v
API Service
        |
        | short transaction
        v
PostgreSQL / MySQL

API Service
        |
        | publish event
        v
Redis Stream / NATS / Kafka
        |
        v
Realtime Gateway
        |
        | WebSocket
        v
Online Clients
```

Ý tưởng chính:

- API xử lý nghiệp vụ và ghi database.
- Transaction phải ngắn.
- Sau khi commit, API publish event vào message broker.
- Realtime Gateway nhận event và đẩy tới client.
- Worker xử lý các việc phụ như notification, email, search indexing.

---

### 4.2. Stack phù hợp cho bản MVP

Với Find My Team, chưa cần copy toàn bộ Discord. Stack thực tế hơn:

| Thành phần | Đề xuất |
|---|---|
| Backend API | Spring Boot / ASP.NET Core / Node.js |
| Database | PostgreSQL |
| Realtime Gateway | WebSocket service riêng |
| Pub/Sub | Redis Pub/Sub hoặc Redis Stream |
| Cache / presence | Redis |
| Background job | Worker service |
| Search ban đầu | PostgreSQL full-text search |
| Search nâng cao | Elasticsearch / OpenSearch |
| File storage | S3 compatible storage |

Với MVP, có thể dùng:

```text
Spring Boot API
PostgreSQL
Redis
WebSocket Gateway
Redis Pub/Sub hoặc Redis Stream
Worker xử lý background job
```

---

## 5. Luồng xử lý chuẩn

### 5.1. Luồng gửi tin nhắn

Không nên:

```text
Client
 -> WebSocket
 -> DB transaction
 -> broadcast
 -> commit
```

Nên dùng:

```text
Client
 -> REST API: POST /messages
 -> validate permission
 -> save message
 -> commit
 -> publish MESSAGE_CREATED event
 -> response nhanh cho client

Realtime Gateway
 -> nhận MESSAGE_CREATED
 -> push tới các user online trong conversation
```

Event mẫu:

```json
{
  "type": "MESSAGE_CREATED",
  "messageId": "msg_123",
  "conversationId": "conv_456",
  "senderId": "user_1",
  "createdAt": "2026-06-11T19:00:00Z"
}
```

---

### 5.2. Luồng match người dùng

```text
User A like User B
 -> API lưu swipe
 -> check nếu User B đã like User A
 -> nếu match thì tạo match record
 -> commit
 -> publish MATCH_CREATED
 -> response
```

Sau đó:

```text
Realtime Gateway
 -> gửi MATCH_CREATED cho User A nếu online
 -> gửi MATCH_CREATED cho User B nếu online

Notification Worker
 -> gửi push notification nếu user offline
```

---

### 5.3. Luồng typing indicator

Typing là event tạm thời, không cần lưu database.

```text
Client
 -> WebSocket: TYPING_START
 -> Gateway kiểm tra user thuộc conversation
 -> gửi cho người còn lại
```

Không cần transaction.

Không cần database.

Không cần message broker nếu chỉ chạy một Gateway. Nếu nhiều Gateway thì dùng Redis Pub/Sub để route event.

---

### 5.4. Luồng online/offline

Khi user connect:

```text
WebSocket connected
 -> Gateway xác thực token
 -> lưu user online vào Redis
 -> publish USER_ONLINE
```

Khi disconnect:

```text
WebSocket disconnected
 -> set TTL ngắn trong Redis
 -> nếu không reconnect thì mark offline
 -> publish USER_OFFLINE
```

Redis key mẫu:

```text
presence:user:{userId} = online
TTL = 60 seconds
```

Gateway cần heartbeat định kỳ để gia hạn TTL.

---

## 6. Thiết kế service

### 6.1. API Service

Nhiệm vụ:

- Đăng nhập / đăng ký
- Quản lý profile
- Quản lý team
- Swipe / match
- Tạo conversation
- Gửi message
- Phân quyền
- Ghi database

Nguyên tắc:

```text
API Service không broadcast WebSocket trực tiếp.
API Service chỉ publish event sau khi commit.
```

---

### 6.2. Realtime Gateway

Nhiệm vụ:

- Giữ kết nối WebSocket
- Authenticate connection
- Subscribe event từ Redis/NATS/Kafka
- Push event tới đúng user
- Quản lý room membership
- Heartbeat
- Reconnect
- Rate limit realtime event

Gateway không nên chứa business logic phức tạp.

---

### 6.3. Message Broker

Có thể chọn theo quy mô:

| Công nghệ | Khi nào dùng |
|---|---|
| Redis Pub/Sub | MVP, đơn giản, realtime nhẹ |
| Redis Stream | Cần lưu event tạm, consumer group |
| NATS | Realtime event nhanh, nhẹ |
| Kafka | Event lớn, cần replay, analytics, log lâu dài |

Khuyến nghị:

```text
MVP: Redis Pub/Sub hoặc Redis Stream
Scale hơn: NATS
Cực lớn / analytics mạnh: Kafka
```

---

### 6.4. Worker Service

Nhiệm vụ:

- Gửi email
- Push notification
- Index search
- Tính unread count
- Gửi digest
- Xử lý báo cáo
- Xử lý tác vụ AI

Worker giúp API không bị chậm vì việc phụ.

---

## 7. Database design cho realtime

### 7.1. Dữ liệu nên lưu database

| Dữ liệu | Lưu DB? |
|---|---|
| User profile | Có |
| Team | Có |
| Team member | Có |
| Swipe | Có |
| Match | Có |
| Message | Có |
| Conversation | Có |
| Online status | Không nên, dùng Redis |
| Typing status | Không |
| Temporary notification state | Redis / Queue |
| Read receipt | Có thể lưu DB hoặc Redis rồi flush |

---

### 7.2. Transaction nên ngắn

Ví dụ gửi message:

```text
BEGIN
 -> insert message
 -> update conversation last_message_at
COMMIT
 -> publish MESSAGE_CREATED
```

Không nên:

```text
BEGIN
 -> insert message
 -> update conversation
 -> push websocket
 -> send notification
 -> index search
COMMIT
```

---

## 8. Optimistic UI

Muốn cảm giác mượt giống Discord, frontend cũng phải làm tốt.

Khi user gửi message:

```text
User bấm Send
 -> UI hiện message tạm ngay lập tức
 -> status = sending
 -> API lưu thành công
 -> status = sent
 -> nếu lỗi thì status = failed
```

Không nên bắt user chờ server xong mới hiện message.

Message tạm có thể dùng `clientMessageId`.

Ví dụ:

```json
{
  "clientMessageId": "local_abc_123",
  "content": "Hello",
  "status": "sending"
}
```

Khi server trả về:

```json
{
  "clientMessageId": "local_abc_123",
  "messageId": "msg_999",
  "status": "sent"
}
```

---

## 9. Idempotency để tránh gửi trùng

Realtime rất dễ bị gửi trùng do retry, reconnect hoặc mạng yếu.

Khi gửi message, client nên gửi kèm `clientMessageId`.

Database có unique constraint:

```sql
UNIQUE(sender_id, client_message_id)
```

Nếu client retry cùng một message, server không tạo message mới mà trả lại message cũ.

---

## 10. Rate limit

Realtime cần rate limit để tránh spam.

Ví dụ:

| Event | Limit gợi ý |
|---|---|
| Send message | 5-10 message / 10 giây |
| Typing event | 1 event / 2 giây |
| Presence update | heartbeat định kỳ |
| Swipe | 20-50 lần / phút |
| Join room | giới hạn theo user |

Rate limit nên lưu ở Redis.

Key mẫu:

```text
rate:user:{userId}:send_message
rate:user:{userId}:typing
```

---

## 11. Reconnect và resume

Client mobile/web có thể mất mạng liên tục. Realtime Gateway cần hỗ trợ:

- reconnect
- heartbeat
- last event id
- sync lại missed event

Luồng gợi ý:

```text
Client reconnect
 -> gửi lastEventId
 -> server kiểm tra event sau lastEventId
 -> gửi lại event bị thiếu
 -> tiếp tục realtime
```

Nếu dùng Redis Stream/NATS/Kafka, việc replay event sẽ dễ hơn Redis Pub/Sub.

---

## 12. Monitoring cần có

Để biết hệ thống lag ở đâu, cần đo:

| Metric | Ý nghĩa |
|---|---|
| API latency | API chậm hay nhanh |
| DB transaction time | Transaction có bị giữ lâu không |
| WebSocket connections | Số kết nối realtime |
| Event publish latency | API publish event có chậm không |
| Event delivery latency | Event tới client mất bao lâu |
| Redis memory | Redis có quá tải không |
| Message queue lag | Worker xử lý có bị tồn hàng không |
| Error rate | Tỷ lệ lỗi |
| Reconnect rate | Client có bị rớt nhiều không |

Log quan trọng:

```text
request_id
user_id
event_type
conversation_id
latency_ms
gateway_id
trace_id
```

---

## 13. Checklist tối ưu realtime

### API

- [ ] Transaction ngắn
- [ ] Không emit WebSocket trong transaction
- [ ] Publish event sau commit
- [ ] Có idempotency key
- [ ] Có rate limit
- [ ] Có pagination cho message
- [ ] Không query join nặng trong request realtime

### WebSocket Gateway

- [ ] Tách riêng service
- [ ] Có heartbeat
- [ ] Có reconnect
- [ ] Có room/user mapping
- [ ] Không xử lý business logic nặng
- [ ] Không query DB nhiều
- [ ] Có scale ngang nhiều instance

### Redis / Broker

- [ ] Dùng Redis cho presence
- [ ] Dùng Pub/Sub hoặc Stream cho event
- [ ] Có TTL cho online status
- [ ] Có key naming rõ ràng
- [ ] Có monitoring memory và latency

### Frontend

- [ ] Optimistic UI
- [ ] Message status: sending/sent/failed
- [ ] Retry khi lỗi
- [ ] Deduplicate bằng clientMessageId
- [ ] Reconnect tự động
- [ ] Sync missed message khi reconnect

---

## 14. Kiến trúc MVP khuyến nghị

```text
[Flutter/Web Client]
        |
        | REST
        v
[Backend API - Spring Boot]
        |
        | short transaction
        v
[PostgreSQL]
        |
        ^
        |
[Redis]
  |   |
  |   +-- Presence / Rate limit / Cache
  |
  +-- Pub/Sub hoặc Stream
        |
        v
[WebSocket Gateway]
        |
        v
[Online Clients]

[Worker Service]
  -> Notification
  -> Email
  -> Search indexing
  -> Background jobs
```

---

## 15. Lộ trình triển khai

### Giai đoạn 1: MVP ổn định

- REST API xử lý nghiệp vụ chính
- PostgreSQL lưu user, team, swipe, match, message
- Redis lưu online status
- WebSocket Gateway riêng
- Redis Pub/Sub cho event realtime
- Optimistic UI cho chat

### Giai đoạn 2: Tối ưu scale

- Redis Stream thay Pub/Sub nếu cần replay event
- Tách Notification Worker
- Tách Search Worker
- Thêm monitoring bằng Prometheus + Grafana
- Thêm tracing request/event

### Giai đoạn 3: Scale lớn

- Chuyển sang NATS hoặc Kafka
- Sharding Gateway
- Dedicated message storage nếu message quá lớn
- Search dùng Elasticsearch/OpenSearch
- Multi-region nếu có nhiều user ở nhiều khu vực

---

## 16. Kết luận

Discord realtime mượt không phải vì họ chỉ dùng WebSocket, mà vì họ thiết kế hệ thống theo hướng:

```text
Realtime Gateway nhẹ
Transaction database ngắn
Event-driven architecture
Worker xử lý việc nặng
Cache/presence bằng Redis
Frontend có optimistic UI
```

Với Find My Team, hướng phù hợp nhất là:

```text
Backend API riêng
WebSocket Gateway riêng
Redis làm Pub/Sub + Presence
PostgreSQL làm database chính
Worker xử lý notification/search/email
```

Chỉ cần tách WebSocket khỏi transaction nặng, hệ thống sẽ mượt và dễ scale hơn rất nhiều.
