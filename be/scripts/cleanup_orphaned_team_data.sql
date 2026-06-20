-- ============================================================
-- SCRIPT DỌN DẸP DỮ LIỆU RÁC TEAM/TEAM_MEMBER
-- Database: PostgreSQL
-- ============================================================

-- 1. XEM THÔNG TIN USER HIỆN TẠI VÀ TEAM ĐANG BỊ KẸT
-- Thay 'YOUR_USER_ID_HERE' bằng UUID của user bị kẹt
-- Hoặc chạy câu lệnh này để xem tất cả user có team kẹt:

-- Xem tất cả user có team membership ở trạng thái ACTIVE nhưng team đã disbanded:
SELECT 
    tm.id as member_id,
    tm.user_id,
    tm.team_id,
    tm.status as member_status,
    t.name as team_name,
    t.status as team_status,
    u.username,
    u.display_name
FROM team_members tm
JOIN teams t ON tm.team_id = t.id
JOIN users u ON tm.user_id = u.id
WHERE tm.status = 'ACTIVE' AND t.status = 'disbanded'
ORDER BY tm.user_id;

-- 2. SỬA LỖI: Cập nhật tất cả team_members của disbanded team về LEFT
-- Chạy câu lệnh này để fix tất cả trường hợp kẹt:

UPDATE team_members
SET status = 'LEFT', left_at = NOW()
WHERE team_id IN (
    SELECT id FROM teams WHERE status = 'disbanded'
)
AND status = 'ACTIVE';

-- 3. KIỂM TRA KẾT QUẢ
-- Sau khi chạy UPDATE, xác nhận không còn membership ACTIVE nào với disbanded team:

SELECT COUNT(*) as orphaned_members
FROM team_members tm
JOIN teams t ON tm.team_id = t.id
WHERE tm.status = 'ACTIVE' AND t.status = 'disbanded';

-- Nếu orphaned_members = 0 thì đã sạch!

-- 4. TÌM VÀ SỬA NHÓM CÓ TÊN "s" HOẶC NHÓM KẸT CỦA USER CỤ THỂ
-- Thay 'USER_UUID' bằng UUID thực tế của user

-- Xem team có tên lạ:
SELECT id, name, owner_id, status, created_at
FROM teams
WHERE name = 's' OR name LIKE '%s%' AND LENGTH(name) <= 3
ORDER BY created_at DESC;

-- Xem team member đang bị kẹt:
SELECT tm.*, t.name as team_name, t.status as team_status
FROM team_members tm
JOIN teams t ON tm.team_id = t.id
WHERE tm.user_id = 'USER_UUID'
ORDER BY tm.joined_at DESC;

-- 5. FIX THỦ CÔNG: Đánh dấu user rời nhóm cụ thể
-- Thay USER_ID và TEAM_ID thực tế

UPDATE team_members
SET status = 'LEFT', left_at = NOW()
WHERE user_id = 'USER_ID' AND team_id = 'TEAM_ID' AND status = 'ACTIVE';

-- 6. XÓA TEAM KẸT (nếu cần)
-- Xóa team có tên "s":

-- TRƯỚC KHI XÓA: Đảm bảo đã UPDATE team_members
UPDATE team_members SET status = 'LEFT', left_at = NOW()
WHERE team_id = (SELECT id FROM teams WHERE name = 's' LIMIT 1);

-- Sau đó xóa team (hoặc soft delete):
UPDATE teams SET status = 'disbanded' WHERE name = 's';

-- 7. VERIFY: Kiểm tra user profile sau khi fix
-- Chạy API hoặc query này để xác nhận:

SELECT 
    u.id,
    u.username,
    u.display_name,
    tm.team_id,
    t.name as team_name,
    t.status as team_status,
    tm.status as member_status
FROM users u
LEFT JOIN team_members tm ON u.id = tm.user_id AND tm.status = 'ACTIVE'
LEFT JOIN teams t ON tm.team_id = t.id
WHERE u.id = 'USER_UUID';

-- ============================================================
-- LƯU Ý QUAN TRỌNG:
-- - Backup database trước khi chạy script này!
-- - Chạy từng bước và kiểm tra kết quả
-- - Với production: nên có transaction và rollback plan
-- ============================================================
