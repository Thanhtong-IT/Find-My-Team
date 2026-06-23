ALTER TABLE user_game_profiles
    ADD COLUMN riot_game_name VARCHAR(100),
    ADD COLUMN riot_tag_line VARCHAR(20),
    ADD COLUMN riot_puuid VARCHAR(100),
    ADD COLUMN riot_region VARCHAR(20),
    ADD COLUMN riot_verification_status VARCHAR(20) NOT NULL DEFAULT 'UNVERIFIED',
    ADD COLUMN riot_verified_at TIMESTAMPTZ,
    ADD COLUMN riot_profile_last_synced_at TIMESTAMPTZ,
    ADD COLUMN rank_source VARCHAR(20) NOT NULL DEFAULT 'MANUAL',
    ADD COLUMN verified_rank VARCHAR(50);

CREATE INDEX idx_user_game_profiles_riot_puuid
    ON user_game_profiles(riot_puuid)
    WHERE riot_puuid IS NOT NULL;

CREATE UNIQUE INDEX uq_user_game_profiles_game_riot_puuid
    ON user_game_profiles(game_id, riot_puuid)
    WHERE riot_puuid IS NOT NULL;
