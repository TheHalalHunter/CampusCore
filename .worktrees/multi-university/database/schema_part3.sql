-- CampusCore Schema — Part 3: Resources, Community, Progress

CREATE TABLE resources (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title          VARCHAR(400) NOT NULL,
  description    TEXT,
  file_url       TEXT NOT NULL,
  file_type      VARCHAR(20),
  file_size      INTEGER,
  type           resource_type NOT NULL DEFAULT 'other',
  status         resource_status NOT NULL DEFAULT 'pending',
  course_id      UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  uploader_id    UUID NOT NULL REFERENCES users(id)  ON DELETE CASCADE,
  reviewed_by    UUID REFERENCES users(id)           ON DELETE SET NULL,
  review_note    TEXT,
  academic_year  VARCHAR(20),
  is_official    BOOLEAN NOT NULL DEFAULT FALSE,
  download_count INTEGER NOT NULL DEFAULT 0,
  version        SMALLINT NOT NULL DEFAULT 1,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_resources_course   ON resources(course_id);
CREATE INDEX idx_resources_uploader ON resources(uploader_id);
CREATE INDEX idx_resources_status   ON resources(status);

CREATE TABLE personal_library (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES users(id)     ON DELETE CASCADE,
  resource_id UUID NOT NULL REFERENCES resources(id) ON DELETE CASCADE,
  note        TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, resource_id)
);

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
CREATE INDEX idx_questions_created    ON questions(created_at DESC);

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

CREATE TABLE connections (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  requester_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  addressee_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  is_accepted  BOOLEAN NOT NULL DEFAULT FALSE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (requester_id, addressee_id),
  CHECK (requester_id <> addressee_id)
);

CREATE TABLE progress (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id      UUID NOT NULL REFERENCES users(id)   ON DELETE CASCADE,
  course_id    UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
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
