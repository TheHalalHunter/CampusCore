-- ============================================================
-- CampusCore — Enable Row Level Security on all tables
-- ============================================================
-- Purpose:
--   The CampusCore NestJS backend uses the DATABASE_URL (Supabase service role
--   connection string) which BYPASSES RLS entirely. All legitimate data access
--   goes through the NestJS API.
--
--   By denying the 'anon' and 'authenticated' roles here, we ensure that:
--   1. Any accidental direct Supabase client access is blocked.
--   2. The Flutter app's Supabase anon key cannot read/write database rows.
--   3. Only the backend service-role connection can access data.
--
-- HOW TO RUN:
--   Paste this script into the Supabase SQL Editor (Dashboard → SQL Editor)
--   and run it once. It is idempotent — safe to re-run.
-- ============================================================

-- Users table
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
CREATE POLICY IF NOT EXISTS "deny_anon_users" ON users FOR ALL TO anon USING (false);
CREATE POLICY IF NOT EXISTS "deny_authenticated_users" ON users FOR ALL TO authenticated USING (false);

-- Departments table
ALTER TABLE departments ENABLE ROW LEVEL SECURITY;
CREATE POLICY IF NOT EXISTS "deny_anon_departments" ON departments FOR ALL TO anon USING (false);
CREATE POLICY IF NOT EXISTS "deny_authenticated_departments" ON departments FOR ALL TO authenticated USING (false);

-- Courses table
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
CREATE POLICY IF NOT EXISTS "deny_anon_courses" ON courses FOR ALL TO anon USING (false);
CREATE POLICY IF NOT EXISTS "deny_authenticated_courses" ON courses FOR ALL TO authenticated USING (false);

-- Resources table
ALTER TABLE resources ENABLE ROW LEVEL SECURITY;
CREATE POLICY IF NOT EXISTS "deny_anon_resources" ON resources FOR ALL TO anon USING (false);
CREATE POLICY IF NOT EXISTS "deny_authenticated_resources" ON resources FOR ALL TO authenticated USING (false);

-- Questions table
ALTER TABLE questions ENABLE ROW LEVEL SECURITY;
CREATE POLICY IF NOT EXISTS "deny_anon_questions" ON questions FOR ALL TO anon USING (false);
CREATE POLICY IF NOT EXISTS "deny_authenticated_questions" ON questions FOR ALL TO authenticated USING (false);

-- Answers table
ALTER TABLE answers ENABLE ROW LEVEL SECURITY;
CREATE POLICY IF NOT EXISTS "deny_anon_answers" ON answers FOR ALL TO anon USING (false);
CREATE POLICY IF NOT EXISTS "deny_authenticated_answers" ON answers FOR ALL TO authenticated USING (false);

-- Notifications table
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY IF NOT EXISTS "deny_anon_notifications" ON notifications FOR ALL TO anon USING (false);
CREATE POLICY IF NOT EXISTS "deny_authenticated_notifications" ON notifications FOR ALL TO authenticated USING (false);

-- User badges table
ALTER TABLE user_badges ENABLE ROW LEVEL SECURITY;
CREATE POLICY IF NOT EXISTS "deny_anon_user_badges" ON user_badges FOR ALL TO anon USING (false);
CREATE POLICY IF NOT EXISTS "deny_authenticated_user_badges" ON user_badges FOR ALL TO authenticated USING (false);

-- Progress table
ALTER TABLE progress ENABLE ROW LEVEL SECURITY;
CREATE POLICY IF NOT EXISTS "deny_anon_progress" ON progress FOR ALL TO anon USING (false);
CREATE POLICY IF NOT EXISTS "deny_authenticated_progress" ON progress FOR ALL TO authenticated USING (false);

-- GPA semesters table
ALTER TABLE gpa_semesters ENABLE ROW LEVEL SECURITY;
CREATE POLICY IF NOT EXISTS "deny_anon_gpa_semesters" ON gpa_semesters FOR ALL TO anon USING (false);
CREATE POLICY IF NOT EXISTS "deny_authenticated_gpa_semesters" ON gpa_semesters FOR ALL TO authenticated USING (false);

-- Connections table
ALTER TABLE connections ENABLE ROW LEVEL SECURITY;
CREATE POLICY IF NOT EXISTS "deny_anon_connections" ON connections FOR ALL TO anon USING (false);
CREATE POLICY IF NOT EXISTS "deny_authenticated_connections" ON connections FOR ALL TO authenticated USING (false);

-- Personal library table
ALTER TABLE personal_library ENABLE ROW LEVEL SECURITY;
CREATE POLICY IF NOT EXISTS "deny_anon_personal_library" ON personal_library FOR ALL TO anon USING (false);
CREATE POLICY IF NOT EXISTS "deny_authenticated_personal_library" ON personal_library FOR ALL TO authenticated USING (false);

-- Study groups table
ALTER TABLE study_groups ENABLE ROW LEVEL SECURITY;
CREATE POLICY IF NOT EXISTS "deny_anon_study_groups" ON study_groups FOR ALL TO anon USING (false);
CREATE POLICY IF NOT EXISTS "deny_authenticated_study_groups" ON study_groups FOR ALL TO authenticated USING (false);

-- Study group members table
ALTER TABLE study_group_members ENABLE ROW LEVEL SECURITY;
CREATE POLICY IF NOT EXISTS "deny_anon_study_group_members" ON study_group_members FOR ALL TO anon USING (false);
CREATE POLICY IF NOT EXISTS "deny_authenticated_study_group_members" ON study_group_members FOR ALL TO authenticated USING (false);

-- AI usage table
ALTER TABLE ai_usage ENABLE ROW LEVEL SECURITY;
CREATE POLICY IF NOT EXISTS "deny_anon_ai_usage" ON ai_usage FOR ALL TO anon USING (false);
CREATE POLICY IF NOT EXISTS "deny_authenticated_ai_usage" ON ai_usage FOR ALL TO authenticated USING (false);

-- Exam locks table
ALTER TABLE exam_locks ENABLE ROW LEVEL SECURITY;
CREATE POLICY IF NOT EXISTS "deny_anon_exam_locks" ON exam_locks FOR ALL TO anon USING (false);
CREATE POLICY IF NOT EXISTS "deny_authenticated_exam_locks" ON exam_locks FOR ALL TO authenticated USING (false);

-- Discussion threads table
ALTER TABLE discussion_threads ENABLE ROW LEVEL SECURITY;
CREATE POLICY IF NOT EXISTS "deny_anon_discussion_threads" ON discussion_threads FOR ALL TO anon USING (false);
CREATE POLICY IF NOT EXISTS "deny_authenticated_discussion_threads" ON discussion_threads FOR ALL TO authenticated USING (false);

-- Discussion replies table
ALTER TABLE discussion_replies ENABLE ROW LEVEL SECURITY;
CREATE POLICY IF NOT EXISTS "deny_anon_discussion_replies" ON discussion_replies FOR ALL TO anon USING (false);
CREATE POLICY IF NOT EXISTS "deny_authenticated_discussion_replies" ON discussion_replies FOR ALL TO authenticated USING (false);

-- ============================================================
-- Supabase Storage Bucket Policy Notes
-- ============================================================
-- Storage buckets are NOT covered by database RLS.
-- Configure them separately in Supabase Dashboard → Storage → Policies:
--
-- Bucket: resources (or your file upload bucket)
--   READ  policy: allow anon READ (public file URLs work without auth)
--   INSERT policy: restrict uploads — require the request to come from the
--                  NestJS backend (which validates the user JWT before
--                  generating a signed upload URL). Do NOT allow direct
--                  anon/client uploads bypassing the backend.
--
-- Bucket: avatars (user profile pictures)
--   READ  policy: allow anon READ
--   INSERT/UPDATE: restrict to authenticated service-role calls
--
-- The anon key in the Flutter apps should only be used for Storage READ
-- operations. All other Supabase SDK calls from the Flutter clients should
-- go through the NestJS backend API.
-- ============================================================
