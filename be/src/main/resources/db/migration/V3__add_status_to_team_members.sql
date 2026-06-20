-- Add status and left_at columns to team_members table
-- status: ACTIVE or LEFT (soft delete)
-- left_at: timestamp when member left

ALTER TABLE team_members
ADD COLUMN IF NOT EXISTS status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE';

ALTER TABLE team_members
ADD COLUMN IF NOT EXISTS left_at TIMESTAMP WITH TIME ZONE;

-- Create index for faster active member queries
CREATE INDEX IF NOT EXISTS idx_team_members_team_status
ON team_members(team_id, status)
WHERE status = 'ACTIVE';
