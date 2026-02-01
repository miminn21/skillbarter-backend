-- Migration: Add FCM Token Column for Push Notifications
-- Date: 2026-02-01
-- Description: Add fcm_token column to User table for Firebase Cloud Messaging

-- Add fcm_token column to User table (Railway Cloud)
ALTER TABLE User 
ADD COLUMN fcm_token VARCHAR(255) NULL 
COMMENT 'Firebase Cloud Messaging device token for push notifications';

-- Add index for faster lookups
CREATE INDEX idx_fcm_token ON User(fcm_token);

-- Also add to local pengguna table (if using local database)
ALTER TABLE pengguna 
ADD COLUMN fcm_token VARCHAR(255) NULL 
COMMENT 'Firebase Cloud Messaging device token for push notifications';

-- Add index for local table
CREATE INDEX idx_fcm_token ON pengguna(fcm_token);
