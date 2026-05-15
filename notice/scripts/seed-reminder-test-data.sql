-- Safe near-future reminder data for Android local notification testing.
-- Run: psql -U postgres -d college_notice -f scripts/seed-reminder-test-data.sql

BEGIN;

ALTER TABLE notices DROP CONSTRAINT IF EXISTS notices_category_check;
ALTER TABLE notices ADD CONSTRAINT notices_category_check
    CHECK (category IN ('GENERAL', 'EXAM', 'ASSIGNMENT', 'EVENT', 'PLACEMENT', 'FEES', 'FINANCE', 'WORKSHOP', 'HOLIDAY'));

INSERT INTO notices (title, description, priority, category, pinned, view_count, created_at, expiry_date, created_by)
SELECT v.title, v.description, v.priority, v.category, v.pinned, 0, NOW(), NOW() + v.offset_interval, a.id
FROM (SELECT id FROM users WHERE role = 'ADMIN' ORDER BY id LIMIT 1) a
CROSS JOIN (VALUES
    ('Reminder Test: Final Hour Lab Upload',
     'Demo deadline for validating urgent local notifications in the final hour.',
     'HIGH', 'ASSIGNMENT', true, INTERVAL '35 minutes'),
    ('Reminder Test: Placement Form Today',
     'Demo deadline inside six hours for hourly reminder validation.',
     'HIGH', 'PLACEMENT', true, INTERVAL '4 hours'),
    ('Reminder Test: Workshop Confirmation Tomorrow',
     'Demo deadline inside twenty four hours for six-hour reminder validation.',
     'MEDIUM', 'WORKSHOP', false, INTERVAL '22 hours'),
    ('Reminder Test: Exam Briefing Later',
     'Demo deadline beyond twenty four hours for the 24-hour-before reminder.',
     'HIGH', 'EXAM', false, INTERVAL '30 hours')
) AS v(title, description, priority, category, pinned, offset_interval)
WHERE NOT EXISTS (
    SELECT 1 FROM notices n WHERE n.title = v.title
);

WITH target_notices AS (
    SELECT id FROM notices WHERE title LIKE 'Reminder Test:%'
),
student_users AS (
    SELECT id FROM users WHERE role = 'STUDENT'
)
INSERT INTO notifications (user_id, notice_id, message, type, is_read, is_acknowledged, created_at)
SELECT u.id, n.id, 'New notice published: ' || no.title, 'NORMAL', false, false, NOW()
FROM target_notices n
JOIN notices no ON no.id = n.id
CROSS JOIN student_users u
WHERE NOT EXISTS (
    SELECT 1 FROM notifications nf
    WHERE nf.user_id = u.id
      AND nf.notice_id = n.id
      AND nf.type = 'NORMAL'
);

WITH target_notices AS (
    SELECT id FROM notices WHERE title LIKE 'Reminder Test:%'
),
student_users AS (
    SELECT id FROM users WHERE role = 'STUDENT'
)
INSERT INTO notice_status (user_id, notice_id, is_read, is_acknowledged, viewed)
SELECT u.id, n.id, false, false, false
FROM target_notices n
CROSS JOIN student_users u
WHERE NOT EXISTS (
    SELECT 1 FROM notice_status ns
    WHERE ns.user_id = u.id
      AND ns.notice_id = n.id
);

SELECT setval(pg_get_serial_sequence('notices', 'id'), COALESCE((SELECT MAX(id) FROM notices), 1));
SELECT setval(pg_get_serial_sequence('notifications', 'id'), COALESCE((SELECT MAX(id) FROM notifications), 1));
SELECT setval(pg_get_serial_sequence('notice_status', 'id'), COALESCE((SELECT MAX(id) FROM notice_status), 1));

COMMIT;
