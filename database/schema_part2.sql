-- CampusCore Schema — Part 2: Core Tables

CREATE TABLE departments (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name             VARCHAR(200) NOT NULL,
  description      TEXT,
  university_name  VARCHAR(200) NOT NULL,
  is_active        BOOLEAN NOT NULL DEFAULT TRUE,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO departments (name, university_name)
VALUES ('Fisheries & Aquaculture', 'LAUTECH');

CREATE TABLE users (
  id                        UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email                     VARCHAR(320) NOT NULL UNIQUE,
  firebase_uid              VARCHAR(128) UNIQUE,
  full_name                 VARCHAR(200) NOT NULL,
  avatar                    TEXT,
  phone                     VARCHAR(20),
  role                      user_role NOT NULL DEFAULT 'student',
  department_id             UUID REFERENCES departments(id) ON DELETE SET NULL,
  academic_level            VARCHAR(10),
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

CREATE TABLE courses (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title          VARCHAR(300) NOT NULL,
  course_code    VARCHAR(20)  NOT NULL,
  description    TEXT,
  department_id  UUID NOT NULL REFERENCES departments(id) ON DELETE CASCADE,
  credit_units   SMALLINT NOT NULL DEFAULT 2,
  academic_level VARCHAR(10) NOT NULL,
  semester       SMALLINT NOT NULL DEFAULT 1 CHECK (semester IN (1, 2)),
  is_active      BOOLEAN NOT NULL DEFAULT TRUE,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_courses_department ON courses(department_id);
CREATE INDEX idx_courses_level      ON courses(academic_level);
