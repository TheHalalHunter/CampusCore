-- =============================================================================
-- CampusCore Migration 003 — Add study streaks table
-- Run in Supabase SQL editor
-- =============================================================================

CREATE TABLE IF NOT EXISTS study_streaks (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id          UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  current_streak   INTEGER NOT NULL DEFAULT 0,
  longest_streak   INTEGER NOT NULL DEFAULT 0,
  last_study_date  DATE,
  total_study_days INTEGER NOT NULL DEFAULT 0,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_study_streaks_user ON study_streaks(user_id);

CREATE TRIGGER trg_study_streaks_updated_at
  BEFORE UPDATE ON study_streaks
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
