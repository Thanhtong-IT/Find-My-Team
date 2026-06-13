-- V2: Add unread_count to community_members table for notification badge

ALTER TABLE community_members
ADD COLUMN unread_count INTEGER NOT NULL DEFAULT 0;
