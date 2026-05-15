-- Deep audit normalization for the demo PostgreSQL database.
-- Safe to rerun. Does not drop or truncate tables.
-- Run: psql -U postgres -d college_notice -f scripts/audit-normalize-demo-data.sql

BEGIN;

ALTER TABLE users ADD COLUMN IF NOT EXISTS division varchar(255);
ALTER TABLE users ADD COLUMN IF NOT EXISTS batch varchar(255);
ALTER TABLE notice_targets ADD COLUMN IF NOT EXISTS division varchar(255);
ALTER TABLE notice_targets ADD COLUMN IF NOT EXISTS batch varchar(255);
ALTER TABLE notices ADD COLUMN IF NOT EXISTS state varchar(24) NOT NULL DEFAULT 'ACTIVE';

ALTER TABLE notices DROP CONSTRAINT IF EXISTS notices_category_check;
ALTER TABLE notices ADD CONSTRAINT notices_category_check
    CHECK (category IN ('GENERAL', 'EXAM', 'ASSIGNMENT', 'EVENT', 'PLACEMENT', 'FEES', 'FINANCE', 'WORKSHOP', 'HOLIDAY'));

-- Normalize mechanical department naming to one code used by targeting.
UPDATE users
SET department = 'MECH'
WHERE role = 'STUDENT'
  AND department = 'ME';

UPDATE notice_targets
SET department = 'MECH'
WHERE department = 'ME';

-- Admins intentionally do not carry student division/batch scope.
UPDATE users
SET division = NULL,
    batch = NULL
WHERE role = 'ADMIN';

-- Students must have realistic academic scope; existing meaningful values are preserved.
UPDATE users
SET division = CASE
        WHEN division IN ('A', 'B', 'C') THEN division
        WHEN department IN ('CSE', 'IT') AND id % 3 = 0 THEN 'C'
        WHEN id % 2 = 0 THEN 'A'
        ELSE 'B'
    END,
    batch = CASE
        WHEN batch IN ('A1', 'A2', 'B1', 'B2', 'C1', 'C2') THEN batch
        WHEN department IN ('CSE', 'IT') AND id % 3 = 0 THEN 'C1'
        WHEN id % 2 = 0 THEN 'A1'
        ELSE 'B2'
    END
WHERE role = 'STUDENT';

-- Replace ad-hoc test notices with believable demo notices while preserving ids and history.
UPDATE notices
SET title = 'Urgent Fee Receipt Verification',
    description = 'Students with recent online fee payments must verify receipt status with the accounts office before the deadline.',
    category = 'FINANCE',
    priority = 'HIGH',
    pinned = true
WHERE title = 'test';

UPDATE notices
SET title = 'Emergency Anti-Ragging Orientation',
    description = 'Mandatory anti-ragging awareness session for all first-year and newly admitted lateral-entry students.',
    category = 'EVENT',
    priority = 'HIGH',
    pinned = true
WHERE title = 'test1';

UPDATE notices
SET title = 'Capstone Prototype Submission',
    description = 'Final-year project teams must upload prototype screenshots, repository link, and mentor approval note.',
    category = 'ASSIGNMENT',
    priority = 'HIGH',
    pinned = true
WHERE title = 'my test';

UPDATE notices
SET title = 'Mini Project Presentation',
    description = 'Project teams must attend the review with prototype demo, report draft, and mentor approval note.',
    category = 'ASSIGNMENT',
    priority = 'HIGH'
WHERE title = 'Mini project presentation';

-- Keep presentation-critical deadlines rolling into the near future each time this script is run.
UPDATE notices
SET state = 'ACTIVE',
    expiry_date = NOW() + INTERVAL '55 minutes'
WHERE title = 'Urgent Exam Form Deadline - Final Call';

UPDATE notices
SET state = 'ACTIVE',
    expiry_date = NOW() + INTERVAL '3 hours'
WHERE title = 'Cloud Lab Assignment 5 Submission';

UPDATE notices
SET state = 'ACTIVE',
    expiry_date = NOW() + INTERVAL '18 hours'
WHERE title = 'Placement Aptitude Test Slot Booking';

UPDATE notices
SET state = 'ACTIVE',
    expiry_date = NOW() + INTERVAL '30 hours'
WHERE title = 'Cybersecurity Workshop Registration';

-- Keep one rolling near-future deadline for local notification demonstrations.
UPDATE notices
SET state = 'ACTIVE',
    category = 'ASSIGNMENT',
    priority = 'HIGH',
    pinned = true,
    created_at = LEAST(created_at, NOW() - INTERVAL '2 hours'),
    expiry_date = NOW() + INTERVAL '35 minutes'
WHERE title = 'Reminder Test: Final Hour Lab Upload';

UPDATE notices
SET state = 'ACTIVE',
    expiry_date = NOW() + INTERVAL '4 hours'
WHERE title = 'Reminder Test: Placement Form Today';

UPDATE notices
SET state = 'ACTIVE',
    expiry_date = NOW() + INTERVAL '22 hours'
WHERE title = 'Reminder Test: Workshop Confirmation Tomorrow';

UPDATE notices
SET state = 'ACTIVE',
    expiry_date = NOW() + INTERVAL '30 hours'
WHERE title = 'Reminder Test: Exam Briefing Later';

-- Recompute lifecycle states from expiry dates. Archived means older than 15 days.
UPDATE notices
SET state = CASE
        WHEN expiry_date IS NULL THEN 'ACTIVE'
        WHEN expiry_date < NOW() - INTERVAL '15 days' THEN 'ARCHIVED'
        WHEN expiry_date < NOW() THEN 'EXPIRED'
        ELSE 'ACTIVE'
    END;

-- Build the logically targeted student-notice pairs once and use them for consistency.
CREATE TEMP TABLE expected_notice_students ON COMMIT DROP AS
SELECT DISTINCT n.id AS notice_id, u.id AS user_id
FROM notices n
JOIN users u ON u.role = 'STUDENT'
WHERE NOT EXISTS (
        SELECT 1 FROM notice_targets nt WHERE nt.notice_id = n.id
    )
   OR EXISTS (
        SELECT 1
        FROM notice_targets nt
        WHERE nt.notice_id = n.id
          AND nt.department = u.department
          AND nt.year = u.year
          AND (nt.division IS NULL OR u.division IS NULL OR nt.division = u.division)
          AND (nt.batch IS NULL OR u.batch IS NULL OR nt.batch = u.batch)
    );

-- Remove student-flow rows for admins and for students who were never targeted.
DELETE FROM notifications nf
USING users u
WHERE nf.user_id = u.id
  AND u.role = 'ADMIN';

DELETE FROM notice_status ns
USING users u
WHERE ns.user_id = u.id
  AND u.role = 'ADMIN';

DELETE FROM notifications nf
WHERE NOT EXISTS (
    SELECT 1
    FROM expected_notice_students e
    WHERE e.notice_id = nf.notice_id
      AND e.user_id = nf.user_id
);

DELETE FROM notice_status ns
WHERE NOT EXISTS (
    SELECT 1
    FROM expected_notice_students e
    WHERE e.notice_id = ns.notice_id
      AND e.user_id = ns.user_id
);

-- Ensure every targeted student-notice pair has analytics and a normal notification.
INSERT INTO notice_status (user_id, notice_id, is_read, is_acknowledged, viewed)
SELECT e.user_id,
       e.notice_id,
       (e.user_id + e.notice_id) % 3 = 0,
       (e.user_id + e.notice_id) % 5 = 0,
       (e.user_id + e.notice_id) % 2 = 0
FROM expected_notice_students e
WHERE NOT EXISTS (
    SELECT 1
    FROM notice_status ns
    WHERE ns.user_id = e.user_id
      AND ns.notice_id = e.notice_id
);

INSERT INTO notifications (user_id, notice_id, message, type, is_read, is_acknowledged, created_at)
SELECT e.user_id,
       e.notice_id,
       'New notice published: ' || n.title,
       'NORMAL',
       ns.is_read,
       ns.is_acknowledged,
       GREATEST(n.created_at, NOW() - (((e.user_id + e.notice_id) % 72) || ' hours')::interval)
FROM expected_notice_students e
JOIN notices n ON n.id = e.notice_id
JOIN notice_status ns ON ns.user_id = e.user_id AND ns.notice_id = e.notice_id
WHERE NOT EXISTS (
    SELECT 1
    FROM notifications nf
    WHERE nf.user_id = e.user_id
      AND nf.notice_id = e.notice_id
      AND nf.type = 'NORMAL'
);

-- Normalize notification/status state without erasing realistic variation.
UPDATE notifications
SET type = 'NORMAL'
WHERE type NOT IN ('NORMAL', 'REMINDER');

UPDATE notice_status ns
SET is_read = true,
    viewed = true
WHERE ns.is_acknowledged = true
   OR ns.is_read = true;

UPDATE notifications nf
SET is_read = true
WHERE nf.is_acknowledged = true;

UPDATE notifications nf
SET is_read = ns.is_read,
    is_acknowledged = ns.is_acknowledged
FROM notice_status ns
WHERE ns.user_id = nf.user_id
  AND ns.notice_id = nf.notice_id
  AND nf.type = 'NORMAL';

UPDATE notifications nf
SET created_at = n.created_at + INTERVAL '5 minutes'
FROM notices n
WHERE nf.notice_id = n.id
  AND nf.created_at < n.created_at;

UPDATE notice_replies r
SET created_at = n.created_at + INTERVAL '2 hours'
FROM notices n
WHERE r.notice_id = n.id
  AND r.created_at < n.created_at;

UPDATE notices n
SET view_count = COALESCE(v.views, 0)
FROM (
    SELECT notice_id, COUNT(*) AS views
    FROM notice_status
    WHERE viewed = true
    GROUP BY notice_id
) v
WHERE n.id = v.notice_id;

UPDATE notices
SET view_count = 0
WHERE id NOT IN (
    SELECT notice_id FROM notice_status WHERE viewed = true
);

SELECT setval(pg_get_serial_sequence('users', 'id'), COALESCE((SELECT MAX(id) FROM users), 1));
SELECT setval(pg_get_serial_sequence('notices', 'id'), COALESCE((SELECT MAX(id) FROM notices), 1));
SELECT setval(pg_get_serial_sequence('notice_targets', 'id'), COALESCE((SELECT MAX(id) FROM notice_targets), 1));
SELECT setval(pg_get_serial_sequence('notifications', 'id'), COALESCE((SELECT MAX(id) FROM notifications), 1));
SELECT setval(pg_get_serial_sequence('notice_status', 'id'), COALESCE((SELECT MAX(id) FROM notice_status), 1));
SELECT setval(pg_get_serial_sequence('notice_replies', 'id'), COALESCE((SELECT MAX(id) FROM notice_replies), 1));

COMMIT;
