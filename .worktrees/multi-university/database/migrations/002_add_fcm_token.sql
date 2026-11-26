-- =============================================================================
-- CampusCore Migration 002 — Add FCM token column to users
-- Run this in Supabase SQL editor
-- =============================================================================

ALTER TABLE users ADD COLUMN IF NOT EXISTS fcm_token TEXT;
