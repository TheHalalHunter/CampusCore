-- CampusCore Schema — Part 4: GPA, Notifications, Gamification, Reports, Triggers

CREATE TABLE gpa_records (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id        UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  semester       SMALLINT NOT NULL,
  academic_year  VARCHAR(20) NOT NULL,
  academic_level VARCHAR(10) NOT NULL,
  gpa            NUMERIC(4,2) NOT NULL,
  total_units    SMALLINT NOT NULL,
  courses_data   JSONB NOT NULL DEFAULT '[]',
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, semester, academic_year)
);

CREATE INDEX idx_gpa_user ON gpa_records(user_id);

CREATE TABLE notifications (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title      VARCHAR(200) NOT NULL,
  body       TEXT NOT NULL,
  type       notification_type NOT NULL,
  related_id UUID,
  is_read    BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifications_user   ON notifications(user_id);
CREATE INDEX idx_notifications_unread ON notifications(user_id, is_read) WHERE is_read = FALSE;

CREATE TABLE user_badges (
  id        UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id   UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  badge     badge_type NOT NULL,
  earned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, badge)
);

CREATE INDEX idx_badges_user ON user_badges(user_id);

CREATE TABLE reputation_events (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  event_type VARCHAR(50) NOT NULL,
  points     SMALLINT NOT NULL,
  related_id UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_rep_events_user ON reputation_events(user_id);

CREATE TABLE reports (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  reporter_id  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  content_type report_content_type NOT NULL,
  content_id   UUID NOT NULL,
  description  TEXT NOT NULL,
  status       report_status NOT NULL DEFAULT 'open',
  resolved_by  UUID REFERENCES users(id) ON DELETE SET NULL,
  resolved_at  TIMESTAMPTZ,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_reports_status ON reports(status);

-- Auto-update updated_at trigger
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_users_updated_at        BEFORE UPDATE ON users        FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_departments_updated_at  BEFORE UPDATE ON departments  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_courses_updated_at      BEFORE UPDATE ON courses      FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_resources_updated_at    BEFORE UPDATE ON resources    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_questions_updated_at    BEFORE UPDATE ON questions    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_answers_updated_at      BEFORE UPDATE ON answers      FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_progress_updated_at     BEFORE UPDATE ON progress     FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_gpa_records_updated_at  BEFORE UPDATE ON gpa_records  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
