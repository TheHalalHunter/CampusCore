-- =============================================================================
-- CampusCore Database Schema
-- PostgreSQL >= 15
-- Version: 1.0  |  Date: July 2026
-- =============================================================================

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- ENUMS
-- =============================================================================

CREATE TYPE user_role AS ENUM ('student', 'moderator', 'lecturer', 'admin');

CREATE TYPE resource_type AS ENUM (
  'lecture_note', 'past_question', 'slide', 'practical_manual', 'assignment', 'other'
);

CREATE TYPE resource_status AS ENUM ('pending', 'approved', 'rejected');

CREATE TYPE notification_type AS ENUM (
  'new_resource', 'question_answered', 'answer_verified',
  'upload_approved', 'upload_rejected', 'new_discussion',
  'announcement', 'study_reminder', 'badge_earned'
);

CREATE TYPE badge_type AS ENUM (
  'fresh_scholar', 'bookworm', 'top_contributor', 'community_helper', 'ai_explorer'
);

-- =============================================================================
-- DEPARTMENTS
-- =============================================================================

CREATE TABLE departments (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name             VARCHAR(200) NOT NULL,
  description      TEXT,
  university_name  VARCHAR(200) NOT NULL,
  is_active        BOOLEAN NOT NULL DEFAULT TRUE,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Seed: Phase 1 department
INSERT INTO departments (name, university_name)
VALUES ('Fisheries & Aquaculture', 'LAUTECH');

-- =============================================================================
-- USERS
-- =============================================================================

CREATE TABLE users (
  id                        UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email                     VARCHAR(320) NOT NULL UNIQUE,
  firebase_uid              VARCHAR(128) UNIQUE,
  full_name                 VARCHAR(200) NOT NULL,
  avatar                    TEXT,
  phone                     VARCHAR(20),
  role                      user_role NOT NULL DEFAULT 'student',
  department_id             UUID REFERENCES departments(id) ON DELETE SET NULL,
  academic_level            VARCHAR(10),          -- e.g. '100L', '200L'
  matric_number             VARCHAR(50) UNIQUE,
  is_email_verified         BOOLEAN NOT NULL DEFAULT FALSE,
  is_active                 BOOLEAN NOT NULL DEFAULT TRUE,
  reputation_points         INTEGER NOT NULL DEFAULT 0,
  last_seen_at              TIMESTAMPTZ,
  accepted_integrity_policy BOOLEAN NOT NULL DEFAULT FALSE,
  created_at                TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at                TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_users_email        ON users(email);
CREATE INDEX idx_users_firebase_uid ON users(firebase_uid);
CREATE INDEX idx_users_department   ON users(department_id);
CREATE INDEX idx_users_role         ON users(role);

-- =============================================================================
-- COURSES
-- =============================================================================

CREATE TABLE courses (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title         VARCHAR(300) NOT NULL,
  course_code   VARCHAR(20)  NOT NULL,             -- e.g. AQU 201
  description   TEXT,
  department_id UUID NOT NULL REFERENCES departments(id) ON DELETE CASCADE,
  credit_units  SMALLINT NOT NULL DEFAULT 2,
  academic_level VARCHAR(10) NOT NULL,              -- e.g. '200L'
  semester      SMALLINT NOT NULL DEFAULT 1 CHECK (semester IN (1, 2)),
  is_active     BOOLEAN NOT NULL DEFAULT TRUE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_courses_department ON courses(department_id);
CREATE INDEX idx_courses_level      ON courses(academic_level);

-- =============================================================================
-- RESOURCES
-- =============================================================================

CREATE TABLE resources (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title         VARCHAR(400) NOT NULL,
  description   TEXT,
  file_url      TEXT NOT NULL,
  file_type     VARCHAR(20),                        -- pdf, pptx, docx, etc.
  file_size     INTEGER,                            -- bytes
  type          resource_type NOT NULL DEFAULT 'other',
  status        resource_status NOT NULL DEFAULT 'pending',
  course_id     UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  uploader_id   UUID NOT NULL REFERENCES users(id)  ON DELETE CASCADE,
  reviewed_by   UUID REFERENCES users(id)           ON DELETE SET NULL,
  review_note   TEXT,
  academic_year VARCHAR(20),                        -- e.g. '2023/2024'
  is_official   BOOLEAN NOT NULL DEFAULT FALSE,
  download_count INTEGER NOT NULL DEFAULT 0,
  version       SMALLINT NOT NULL DEFAULT 1,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_resources_course   ON resources(course_id);
CREATE INDEX idx_resources_uploader ON resources(uploader_id);
CREATE INDEX idx_resources_status   ON resources(status);
CREATE INDEX idx_resources_type     ON resources(type);

-- =============================================================================
-- PERSONAL LIBRARY  (bookmarks / saves)
-- =============================================================================

CREATE TABLE personal_library (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES users(id)     ON DELETE CASCADE,
  resource_id UUID NOT NULL REFERENCES resources(id) ON DELETE CASCADE,
  note        TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, resource_id)
);

CREATE INDEX idx_library_user ON personal_library(user_id);

-- =============================================================================
-- COMMUNITY — QUESTIONS
-- =============================================================================

CREATE TABLE questions (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title          VARCHAR(500) NOT NULL,
  body           TEXT NOT NULL,
  author_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  course_id      UUID REFERENCES courses(id)        ON DELETE SET NULL,
  department_id  UUID REFERENCES departments(id)    ON DELETE SET NULL,
  academic_level VARCHAR(10),
  upvote_count   INTEGER NOT NULL DEFAULT 0,
  answer_count   INTEGER NOT NULL DEFAULT 0,
  is_resolved    BOOLEAN NOT NULL DEFAULT FALSE,
  is_flagged     BOOLEAN NOT NULL DEFAULT FALSE,
  tags           TEXT[]  NOT NULL DEFAULT '{}',
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_questions_author     ON questions(author_id);
CREATE INDEX idx_questions_department ON questions(department_id);
CREATE INDEX idx_questions_course     ON questions(course_id);
CREATE INDEX idx_questions_created    ON questions(created_at DESC);

-- =============================================================================
-- COMMUNITY — ANSWERS
-- =============================================================================

CREATE TABLE answers (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  body         TEXT NOT NULL,
  question_id  UUID NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
  author_id    UUID NOT NULL REFERENCES users(id)     ON DELETE CASCADE,
  upvote_count INTEGER NOT NULL DEFAULT 0,
  is_verified  BOOLEAN NOT NULL DEFAULT FALSE,
  is_flagged   BOOLEAN NOT NULL DEFAULT FALSE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_answers_question ON answers(question_id);
CREATE INDEX idx_answers_author   ON answers(author_id);

-- =============================================================================
-- CONNECTIONS (peer-to-peer, mutual)
-- =============================================================================

CREATE TABLE connections (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  requester_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  addressee_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  is_accepted  BOOLEAN NOT NULL DEFAULT FALSE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (requester_id, addressee_id),
  CHECK (requester_id <> addressee_id)
);

-- =============================================================================
-- PROGRESS TRACKING
-- =============================================================================

CREATE TABLE progress (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id      UUID NOT NULL REFERENCES users(id)    ON DELETE CASCADE,
  course_id    UUID NOT NULL REFERENCES courses(id)  ON DELETE CASCADE,
  topic_id     VARCHAR(100) NOT NULL,
  topic_title  VARCHAR(300) NOT NULL,
  is_completed BOOLEAN NOT NULL DEFAULT FALSE,
  completed_at TIMESTAMPTZ,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, course_id, topic_id)
);

CREATE INDEX idx_progress_user   ON progress(user_id);
CREATE INDEX idx_progress_course ON progress(user_id, course_id);

-- =============================================================================
-- GPA RECORDS
-- =============================================================================

CREATE TABLE gpa_records (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  semester     SMALLINT NOT NULL,
  academic_year VARCHAR(20) NOT NULL,              -- e.g. '2025/2026'
  academic_level VARCHAR(10) NOT NULL,
  gpa          NUMERIC(4,2) NOT NULL,
  total_units  SMALLINT NOT NULL,
  courses_data JSONB NOT NULL DEFAULT '[]',        -- [{code, title, units, grade, points}]
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, semester, academic_year)
);

CREATE INDEX idx_gpa_user ON gpa_records(user_id);

-- =============================================================================
-- NOTIFICATIONS
-- =============================================================================

CREATE TABLE notifications (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title      VARCHAR(200) NOT NULL,
  body       TEXT NOT NULL,
  type       notification_type NOT NULL,
  related_id UUID,                                 -- ID of the related entity
  is_read    BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifications_user    ON notifications(user_id);
CREATE INDEX idx_notifications_unread  ON notifications(user_id, is_read) WHERE is_read = FALSE;

-- =============================================================================
-- GAMIFICATION — BADGES
-- =============================================================================

CREATE TABLE user_badges (
  id        UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id   UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  badge     badge_type NOT NULL,
  earned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, badge)
);

CREATE INDEX idx_badges_user ON user_badges(user_id);

-- =============================================================================
-- REPUTATION EVENTS  (audit trail)
-- =============================================================================

CREATE TABLE reputation_events (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  event_type VARCHAR(50) NOT NULL,                 -- e.g. 'upload_approved'
  points     SMALLINT NOT NULL,
  related_id UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_rep_events_user ON reputation_events(user_id);

-- =============================================================================
-- REPORTS (flagged content / misconduct)
-- =============================================================================

CREATE TYPE report_status AS ENUM ('open', 'resolved', 'dismissed');
CREATE TYPE report_content_type AS ENUM ('question', 'answer', 'resource', 'user');

CREATE TABLE reports (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  reporter_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  content_type   report_content_type NOT NULL,
  content_id     UUID NOT NULL,
  description    TEXT NOT NULL,
  status         report_status NOT NULL DEFAULT 'open',
  resolved_by    UUID REFERENCES users(id) ON DELETE SET NULL,
  resolved_at    TIMESTAMPTZ,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_reports_status ON reports(status);

-- =============================================================================
-- UPDATED_AT TRIGGER  (auto-update timestamp on row changes)
-- =============================================================================

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to all tables that have updated_at
DO $$
DECLARE
  t TEXT;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'users','departments','courses','resources',
    'questions','answers','progress','gpa_records'
  ] LOOP
    EXECUTE format(
      'CREATE TRIGGER trg_%s_updated_at
       BEFORE UPDATE ON %s
       FOR EACH ROW EXECUTE FUNCTION set_updated_at()',
      t, t
    );
  END LOOP;
END;
$$;
