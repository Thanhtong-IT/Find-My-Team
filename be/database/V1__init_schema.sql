-- ============================================================
-- Find My Team - Database Schema (PostgreSQL)
-- Version: 1.0
-- Kiến trúc: Event-driven Realtime (Discord-style)
-- 
-- Chạy file này trên PostgreSQL 14+ để tạo toàn bộ schema.
-- Lưu ý: Online/Offline status dùng Redis, KHÔNG lưu DB.
-- ============================================================

-- Bật extension UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- 1. USERS & AUTH
-- ============================================================

CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email           VARCHAR(255) UNIQUE NOT NULL,
    username        VARCHAR(50) UNIQUE NOT NULL,
    full_name       VARCHAR(100) NOT NULL,
    password_hash   VARCHAR(255) NOT NULL,
    display_name    VARCHAR(100),
    avatar_url      VARCHAR(500),
    bio             TEXT,
    region          VARCHAR(50),
    last_seen_at    TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);

COMMENT ON TABLE users IS 'Bảng user chính. Online status lưu Redis (presence:user:{id}), KHÔNG lưu DB.';

-- Refresh tokens cho JWT
CREATE TABLE refresh_tokens (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token           VARCHAR(500) UNIQUE NOT NULL,
    expires_at      TIMESTAMPTZ NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_refresh_tokens_user ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_token ON refresh_tokens(token);

-- ============================================================
-- 2. GAMES
-- ============================================================

CREATE TABLE games (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(100) UNIQUE NOT NULL,
    short_name      VARCHAR(50),
    tag             VARCHAR(50),
    gradient_start  VARCHAR(7),
    gradient_end    VARCHAR(7),
    icon_url        VARCHAR(500),
    ranks           JSONB NOT NULL DEFAULT '[]',
    roles           JSONB NOT NULL DEFAULT '[]',
    max_team_size   INT NOT NULL DEFAULT 5,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE games IS 'Danh sách game hỗ trợ. ranks và roles lưu dạng JSON array để frontend render dropdown.';

-- ============================================================
-- 3. USER GAME PROFILES
-- ============================================================

CREATE TABLE user_game_profiles (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    game_id         UUID NOT NULL REFERENCES games(id) ON DELETE CASCADE,
    rank            VARCHAR(50),
    role            VARCHAR(50),
    has_mic         BOOLEAN NOT NULL DEFAULT FALSE,
    is_primary      BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_user_game UNIQUE(user_id, game_id)
);

CREATE INDEX idx_user_game_profiles_user ON user_game_profiles(user_id);
CREATE INDEX idx_user_game_profiles_game ON user_game_profiles(game_id);

COMMENT ON TABLE user_game_profiles IS 'Mỗi user có thể chơi nhiều game, mỗi game có rank/role riêng.';

-- ============================================================
-- 4. TEAMS
-- ============================================================

CREATE TABLE teams (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(100),
    game_id         UUID NOT NULL REFERENCES games(id),
    required_rank   VARCHAR(50),
    max_size        INT NOT NULL DEFAULT 5,
    description     TEXT,
    required_roles  JSONB DEFAULT '[]',
    require_mic     BOOLEAN NOT NULL DEFAULT FALSE,
    status          VARCHAR(20) NOT NULL DEFAULT 'recruiting',
    owner_id        UUID NOT NULL REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_team_status CHECK (status IN ('recruiting', 'full', 'playing', 'disbanded'))
);

CREATE INDEX idx_teams_game ON teams(game_id);
CREATE INDEX idx_teams_owner ON teams(owner_id);
CREATE INDEX idx_teams_status ON teams(status) WHERE status = 'recruiting';

COMMENT ON TABLE teams IS 'Nhóm chơi game. Status recruiting = đang tuyển thành viên.';

-- Thành viên team
CREATE TABLE team_members (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    team_id         UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role            VARCHAR(50) NOT NULL DEFAULT 'member',
    is_ready        BOOLEAN NOT NULL DEFAULT FALSE,
    joined_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_team_member UNIQUE(team_id, user_id),
    CONSTRAINT chk_member_role CHECK (role IN ('owner', 'member'))
);

CREATE INDEX idx_team_members_team ON team_members(team_id);
CREATE INDEX idx_team_members_user ON team_members(user_id);

-- Yêu cầu tham gia team
CREATE TABLE join_requests (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    team_id         UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    message         TEXT,
    status          VARCHAR(20) NOT NULL DEFAULT 'pending',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_join_request UNIQUE(team_id, user_id),
    CONSTRAINT chk_join_status CHECK (status IN ('pending', 'accepted', 'rejected'))
);

CREATE INDEX idx_join_requests_team ON join_requests(team_id, status);
CREATE INDEX idx_join_requests_user ON join_requests(user_id);

-- ============================================================
-- 5. TEAM REQUESTS (user đăng yêu cầu tìm đội)
-- ============================================================

CREATE TABLE team_requests (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    game_id         UUID NOT NULL REFERENCES games(id),
    required_rank   VARCHAR(50),
    required_roles  JSONB DEFAULT '[]',
    require_mic     BOOLEAN NOT NULL DEFAULT FALSE,
    description     TEXT,
    status          VARCHAR(20) NOT NULL DEFAULT 'open',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_request_status CHECK (status IN ('open', 'matched', 'closed'))
);

CREATE INDEX idx_team_requests_user ON team_requests(user_id);
CREATE INDEX idx_team_requests_game ON team_requests(game_id, status);
CREATE INDEX idx_team_requests_open ON team_requests(status, created_at DESC) WHERE status = 'open';

COMMENT ON TABLE team_requests IS 'User đăng yêu cầu tìm đội. Tương ứng CreateRequestScreen trên frontend.';

-- ============================================================
-- 6. SWIPE & MATCH
-- ============================================================

CREATE TABLE swipes (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    swiper_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    target_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    direction       VARCHAR(10) NOT NULL,
    game_id         UUID REFERENCES games(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_swipe UNIQUE(swiper_id, target_id, game_id),
    CONSTRAINT chk_swipe_direction CHECK (direction IN ('like', 'skip')),
    CONSTRAINT chk_swipe_self CHECK (swiper_id != target_id)
);

CREATE INDEX idx_swipes_target ON swipes(target_id, direction) WHERE direction = 'like';

COMMENT ON TABLE swipes IS 'Lưu lượt like/skip. Khi cả 2 like nhau → tạo match (xử lý ở API Service).';

CREATE TABLE matches (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_a_id       UUID NOT NULL REFERENCES users(id),
    user_b_id       UUID NOT NULL REFERENCES users(id),
    game_id         UUID REFERENCES games(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_match UNIQUE(user_a_id, user_b_id),
    CONSTRAINT chk_match_order CHECK (user_a_id < user_b_id)
);

CREATE INDEX idx_matches_user_a ON matches(user_a_id);
CREATE INDEX idx_matches_user_b ON matches(user_b_id);

COMMENT ON CONSTRAINT chk_match_order ON matches IS 'Luôn lưu user_a < user_b để tránh duplicate (A,B) vs (B,A).';

-- ============================================================
-- 7. COMMUNITIES
-- ============================================================

CREATE TABLE communities (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(100) NOT NULL,
    game_id         UUID REFERENCES games(id),
    description     TEXT,
    avatar_url      VARCHAR(500),
    cover_url       VARCHAR(500),
    is_public       BOOLEAN NOT NULL DEFAULT TRUE,
    owner_id        UUID NOT NULL REFERENCES users(id),
    member_count    INT NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_communities_game ON communities(game_id);
CREATE INDEX idx_communities_owner ON communities(owner_id);

-- Channels trong community
CREATE TABLE channels (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    community_id    UUID NOT NULL REFERENCES communities(id) ON DELETE CASCADE,
    name            VARCHAR(100) NOT NULL,
    type            VARCHAR(10) NOT NULL DEFAULT 'text',
    position        INT NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_channel_type CHECK (type IN ('text', 'voice'))
);

CREATE INDEX idx_channels_community ON channels(community_id, position);

-- Thành viên community
CREATE TABLE community_members (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    community_id    UUID NOT NULL REFERENCES communities(id) ON DELETE CASCADE,
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role            VARCHAR(20) NOT NULL DEFAULT 'member',
    joined_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_community_member UNIQUE(community_id, user_id),
    CONSTRAINT chk_community_role CHECK (role IN ('owner', 'admin', 'member'))
);

CREATE INDEX idx_community_members_community ON community_members(community_id);
CREATE INDEX idx_community_members_user ON community_members(user_id);

-- ============================================================
-- 8. MESSAGES (trong channel của community)
-- ============================================================

CREATE TABLE messages (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    channel_id          UUID NOT NULL REFERENCES channels(id) ON DELETE CASCADE,
    sender_id           UUID NOT NULL REFERENCES users(id),
    content             TEXT NOT NULL,
    image_url           VARCHAR(500),
    client_message_id   VARCHAR(100),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Idempotency: tránh gửi trùng khi client retry/reconnect
    CONSTRAINT uq_message_idempotency UNIQUE(sender_id, client_message_id)
);

CREATE INDEX idx_messages_channel ON messages(channel_id, created_at DESC);
CREATE INDEX idx_messages_sender ON messages(sender_id);

COMMENT ON CONSTRAINT uq_message_idempotency ON messages IS
    'Client gửi clientMessageId duy nhất. Nếu retry cùng ID → server trả message cũ thay vì tạo mới. Ref: §9 tài liệu kiến trúc.';

-- ============================================================
-- 9. DIRECT MESSAGES (chat 1-1 hoặc group nhỏ)
-- ============================================================

CREATE TABLE conversations (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type            VARCHAR(20) NOT NULL DEFAULT 'direct',
    last_message_at TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_conversation_type CHECK (type IN ('direct', 'group'))
);

CREATE TABLE conversation_members (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    unread_count    INT NOT NULL DEFAULT 0,
    last_read_at    TIMESTAMPTZ,
    joined_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_conversation_member UNIQUE(conversation_id, user_id)
);

CREATE INDEX idx_conversation_members_user ON conversation_members(user_id);
CREATE INDEX idx_conversation_members_conv ON conversation_members(conversation_id);

CREATE TABLE direct_messages (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id     UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id           UUID NOT NULL REFERENCES users(id),
    content             TEXT NOT NULL,
    image_url           VARCHAR(500),
    client_message_id   VARCHAR(100),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_dm_idempotency UNIQUE(sender_id, client_message_id)
);

CREATE INDEX idx_direct_messages_conv ON direct_messages(conversation_id, created_at DESC);

-- ============================================================
-- 10. NOTIFICATIONS
-- ============================================================

CREATE TABLE notifications (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type            VARCHAR(30) NOT NULL,
    title           VARCHAR(255) NOT NULL,
    body            TEXT,
    is_read         BOOLEAN NOT NULL DEFAULT FALSE,
    action_id       VARCHAR(100),
    action_id_2     VARCHAR(100),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_notification_type CHECK (type IN (
        'team_invite',
        'join_request',
        'community_post',
        'chat_message',
        'request_accepted',
        'request_rejected',
        'match_created',
        'system'
    ))
);

CREATE INDEX idx_notifications_user ON notifications(user_id, created_at DESC);
CREATE INDEX idx_notifications_unread ON notifications(user_id, is_read) WHERE is_read = FALSE;

COMMENT ON TABLE notifications IS 'Thông báo cho user. Frontend có 6 type tương ứng NotificationType enum.';

-- ============================================================
-- 11. INVITATIONS (mời vào team / mời chơi)
-- ============================================================

CREATE TABLE invitations (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    inviter_id      UUID NOT NULL REFERENCES users(id),
    invitee_id      UUID NOT NULL REFERENCES users(id),
    team_id         UUID REFERENCES teams(id) ON DELETE SET NULL,
    type            VARCHAR(20) NOT NULL DEFAULT 'team_invite',
    status          VARCHAR(20) NOT NULL DEFAULT 'pending',
    message         TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_invitation_type CHECK (type IN ('team_invite', 'play_invite')),
    CONSTRAINT chk_invitation_status CHECK (status IN ('pending', 'accepted', 'rejected', 'expired')),
    CONSTRAINT chk_invitation_self CHECK (inviter_id != invitee_id)
);

CREATE INDEX idx_invitations_invitee ON invitations(invitee_id, status);
CREATE INDEX idx_invitations_inviter ON invitations(inviter_id);

-- ============================================================
-- 12. TRIGGER: Tự động cập nhật updated_at
-- ============================================================

CREATE OR REPLACE FUNCTION trigger_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Áp dụng trigger cho các bảng có updated_at
DO $$
DECLARE
    tbl TEXT;
BEGIN
    FOR tbl IN
        SELECT unnest(ARRAY[
            'users',
            'user_game_profiles',
            'teams',
            'join_requests',
            'team_requests',
            'communities',
            'messages',
            'invitations'
        ])
    LOOP
        EXECUTE format(
            'CREATE TRIGGER set_updated_at
             BEFORE UPDATE ON %I
             FOR EACH ROW
             EXECUTE FUNCTION trigger_set_updated_at()',
            tbl
        );
    END LOOP;
END;
$$;

-- ============================================================
-- 13. TRIGGER: Tự động cập nhật member_count của community
-- ============================================================

CREATE OR REPLACE FUNCTION trigger_update_community_member_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE communities SET member_count = member_count + 1 WHERE id = NEW.community_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE communities SET member_count = member_count - 1 WHERE id = OLD.community_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_community_member_count
AFTER INSERT OR DELETE ON community_members
FOR EACH ROW
EXECUTE FUNCTION trigger_update_community_member_count();

-- ============================================================
-- 14. SEED DATA: Danh sách game
-- ============================================================

INSERT INTO games (name, short_name, tag, gradient_start, gradient_end, ranks, roles, max_team_size) VALUES

('Valorant', 'Valorant', 'FPS', '#FD4556', '#BD2020',
 '["Sắt", "Đồng", "Bạc", "Vàng", "Bạch kim", "Kim cương", "Bất tử", "Radiant"]',
 '["Duelist", "Controller", "Initiator", "Sentinel"]',
 5),

('Liên Quân Mobile', 'Liên Quân', 'MOBA 5v5', '#2563EB', '#1D4ED8',
 '["Đồng", "Bạc", "Vàng", "Bạch kim", "Kim cương", "Tinh anh", "Cao thủ", "Thách đấu"]',
 '["Trợ thủ", "Đường giữa", "Rừng", "Xạ thủ", "Đường Caesar"]',
 5),

('Liên Minh Huyền Thoại', 'Liên Minh', 'MOBA PC', '#6D28D9', '#4C1D95',
 '["Sắt", "Đồng", "Bạc", "Vàng", "Bạch kim", "Kim cương", "Cao thủ", "Đại cao thủ", "Thách đấu"]',
 '["Top", "Jungle", "Mid", "ADC", "Support"]',
 5),

('PUBG Mobile', 'PUBG Mobile', 'Battle Royale', '#059669', '#065F46',
 '["Đồng", "Bạc", "Vàng", "Bạch kim", "Kim cương", "Crown", "Ace", "Conqueror"]',
 '["Leader", "Sniper", "Support", "Scout", "Fragger"]',
 4),

('Free Fire', 'Free Fire', 'Battle Royale', '#F59E0B', '#D97706',
 '["Đồng", "Bạc", "Vàng", "Bạch kim", "Kim cương", "Heroic", "Grandmaster"]',
 '["Rusher", "Sniper", "Support", "IGL"]',
 4),

('Genshin Impact', 'Genshin', 'Open World RPG', '#8B5CF6', '#6D28D9',
 '["AR 1-20", "AR 20-35", "AR 35-45", "AR 45-55", "AR 55+"]',
 '["DPS", "Sub DPS", "Support", "Healer"]',
 4);

-- ============================================================
-- 15. VIEW: Thống kê nhanh cho trang chủ
-- ============================================================

-- View: Game phổ biến kèm số team đang tuyển
CREATE OR REPLACE VIEW v_popular_games AS
SELECT
    g.id,
    g.name,
    g.short_name,
    g.tag,
    g.gradient_start,
    g.gradient_end,
    g.ranks,
    g.roles,
    g.max_team_size,
    COUNT(DISTINCT t.id) FILTER (WHERE t.status = 'recruiting') AS active_team_count,
    COUNT(DISTINCT tr.id) FILTER (WHERE tr.status = 'open') AS open_request_count
FROM games g
LEFT JOIN teams t ON t.game_id = g.id
LEFT JOIN team_requests tr ON tr.game_id = g.id
WHERE g.is_active = TRUE
GROUP BY g.id
ORDER BY active_team_count DESC;

-- View: Team đang tuyển (cho Explore & Trang chủ)
CREATE OR REPLACE VIEW v_recruiting_teams AS
SELECT
    t.id,
    t.name AS team_name,
    g.name AS game_name,
    g.short_name AS game_short_name,
    t.required_rank,
    t.max_size,
    t.description,
    t.required_roles,
    t.require_mic,
    t.created_at,
    COUNT(tm.id) AS current_member_count,
    t.max_size - COUNT(tm.id) AS slots_available,
    u.display_name AS owner_name
FROM teams t
JOIN games g ON g.id = t.game_id
JOIN users u ON u.id = t.owner_id
LEFT JOIN team_members tm ON tm.team_id = t.id
WHERE t.status = 'recruiting'
GROUP BY t.id, g.id, u.id
HAVING COUNT(tm.id) < t.max_size
ORDER BY t.created_at DESC;

-- ============================================================
-- DONE
-- ============================================================
-- Schema sẵn sàng. Các dữ liệu tạm thời (online status, typing,
-- rate limit, cache) được lưu ở Redis theo tài liệu kiến trúc.
--
-- Redis keys tham khảo:
--   presence:user:{userId}             = "online"   TTL=60s
--   rate:user:{userId}:send_message    = counter    TTL=10s
--   rate:user:{userId}:typing          = counter    TTL=2s
--   cache:games:popular                = JSON       TTL=60s
--   events:team:{teamId}               = Pub/Sub channel
--   events:channel:{channelId}         = Pub/Sub channel
--   events:user:{userId}               = Pub/Sub channel
-- ============================================================
