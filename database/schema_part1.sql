-- CampusCore Schema — Part 1: Extensions & Enums
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

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

CREATE TYPE report_status AS ENUM ('open', 'resolved', 'dismissed');

CREATE TYPE report_content_type AS ENUM ('question', 'answer', 'resource', 'user');
