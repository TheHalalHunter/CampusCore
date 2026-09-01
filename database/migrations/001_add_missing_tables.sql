-- =============================================================================
-- CampusCore Migration 001 — Add missing tables
-- Run this against your Supabase database in the SQL editor
-- =============================================================================

-- ─── 1. Fix connections table ─────────────────────────────────────────────────
-- The existing schema uses addressee_id + is_accepted boolean.
-- The backend entity uses receiver_id + status enum.
-- We drop the old table and recreate it correctly.
-- NOTE: Only run if connections table is empty (no real data yet).

DROP TABLE IF EXISTS connections CASCADE;

CREATE TYPE connection_status AS ENUM ('pending', 'accepted');

CREATE TABLE connections (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  requester_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  receiver_id  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status       connection_status NOT NULL DEFAULT 'pending',
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (requester_id, receiver_id),
  CHECK (requester_id <> receiver_id)
);

CREATE INDEX idx_connections_requester ON connections(requester_id);
CREATE INDEX idx_connections_receiver  ON connections(receiver_id);
CREATE INDEX idx_connections_status    ON connections(status);

CREATE TRIGGER trg_connections_updated_at
  BEFORE UPDATE ON connections
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


-- ─── 2. GPA Semesters ─────────────────────────────────────────────────────────
-- The entity is gpa_semesters (different from old gpa_records in schema.sql).
-- Keep gpa_records if it has data; add gpa_semesters as the new table.

CREATE TABLE IF NOT EXISTS gpa_semesters (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id        UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  academic_level VARCHAR(10) NOT NULL,
  semester       SMALLINT NOT NULL CHECK (semester IN (1, 2)),
  academic_year  VARCHAR(20),
  courses        JSONB NOT NULL DEFAULT '[]',
  gpa            NUMERIC(4, 2) NOT NULL,
  total_units    SMALLINT NOT NULL,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, academic_level, semester)
);

CREATE INDEX idx_gpa_semesters_user ON gpa_semesters(user_id);

CREATE TRIGGER trg_gpa_semesters_updated_at
  BEFORE UPDATE ON gpa_semesters
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


-- ─── 3. Discussion Threads ────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS discussion_threads (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title          VARCHAR(300) NOT NULL,
  body           TEXT NOT NULL,
  author_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  department_id  UUID NOT NULL REFERENCES departments(id) ON DELETE CASCADE,
  academic_level VARCHAR(10),
  reply_count    INTEGER NOT NULL DEFAULT 0,
  is_pinned      BOOLEAN NOT NULL DEFAULT FALSE,
  is_flagged     BOOLEAN NOT NULL DEFAULT FALSE,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_threads_author     ON discussion_threads(author_id);
CREATE INDEX idx_threads_department ON discussion_threads(department_id);
CREATE INDEX idx_threads_level      ON discussion_threads(academic_level);
CREATE INDEX idx_threads_updated    ON discussion_threads(updated_at DESC);

CREATE TRIGGER trg_threads_updated_at
  BEFORE UPDATE ON discussion_threads
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


-- ─── 4. Discussion Replies ────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS discussion_replies (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  body       TEXT NOT NULL,
  thread_id  UUID NOT NULL REFERENCES discussion_threads(id) ON DELETE CASCADE,
  author_id  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  is_flagged BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_replies_thread ON discussion_replies(thread_id);
CREATE INDEX idx_replies_author ON discussion_replies(author_id);

CREATE TRIGGER trg_replies_updated_at
  BEFORE UPDATE ON discussion_replies
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


-- ─── 5. Exam Locks ────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS exam_locks (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name              VARCHAR(255) NOT NULL,
  starts_at         TIMESTAMP NOT NULL,
  ends_at           TIMESTAMP NOT NULL,
  lock_ai           BOOLEAN NOT NULL DEFAULT TRUE,
  lock_discussions  BOOLEAN NOT NULL DEFAULT TRUE,
  academic_level    VARCHAR(100),
  course_id         VARCHAR(255),
  reason            TEXT,
  active            BOOLEAN NOT NULL DEFAULT FALSE,
  created_by        VARCHAR(255) NOT NULL,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_exam_locks_active ON exam_locks(active);
CREATE INDEX idx_exam_locks_dates  ON exam_locks(starts_at, ends_at);

CREATE TRIGGER trg_exam_locks_updated_at
  BEFORE UPDATE ON exam_locks
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


-- ─── 6. AI Usage ─────────────────────────────────────────────────────────────

CREATE TYPE ai_action AS ENUM (
  'explain', 'quiz', 'flashcards', 'summarize', 'predict_topics'
);

CREATE TABLE IF NOT EXISTS ai_usage (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id        UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  action         ai_action NOT NULL,
  prompt         TEXT NOT NULL,
  tokens_used    INTEGER,
  course_context VARCHAR(255),
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_ai_usage_user   ON ai_usage(user_id);
CREATE INDEX idx_ai_usage_action ON ai_usage(action);


-- ─── 7. Stellar Wallets ───────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS stellar_wallets (
  id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id                 UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  stellar_address         VARCHAR(56) NOT NULL UNIQUE,
  reputation_balance      BIGINT NOT NULL DEFAULT 0,
  is_verified             BOOLEAN NOT NULL DEFAULT FALSE,
  network                 VARCHAR(20) NOT NULL DEFAULT 'testnet',
  reputation_contract_id  VARCHAR(255),
  badge_contract_id       VARCHAR(255),
  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_stellar_wallets_user    ON stellar_wallets(user_id);
CREATE INDEX idx_stellar_wallets_address ON stellar_wallets(stellar_address);

CREATE TRIGGER trg_stellar_wallets_updated_at
  BEFORE UPDATE ON stellar_wallets
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


-- ─── 8. Stellar Transactions ─────────────────────────────────────────────────

CREATE TYPE stellar_tx_type AS ENUM (
  'reputation_award', 'badge_mint', 'contribution_proof'
);

CREATE TYPE stellar_tx_status AS ENUM (
  'pending', 'submitted', 'confirmed', 'failed'
);

CREATE TABLE IF NOT EXISTS stellar_transactions (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type          stellar_tx_type NOT NULL,
  status        stellar_tx_status NOT NULL DEFAULT 'pending',
  tx_hash       VARCHAR(255),
  contract_id   VARCHAR(255),
  payload       JSONB NOT NULL DEFAULT '{}',
  error_message TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_stellar_tx_user   ON stellar_transactions(user_id);
CREATE INDEX idx_stellar_tx_status ON stellar_transactions(status);
CREATE INDEX idx_stellar_tx_type   ON stellar_transactions(type);


-- =============================================================================
-- Done. All missing tables created.
-- =============================================================================
