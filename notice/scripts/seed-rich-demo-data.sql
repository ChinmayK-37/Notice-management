-- Rich production-like demo data for Notice Circular Management System.
-- Safe to rerun. Does not drop or truncate tables.
-- Run: psql -U postgres -d college_notice -f scripts/seed-rich-demo-data.sql

BEGIN;

ALTER TABLE users ADD COLUMN IF NOT EXISTS division varchar(255);
ALTER TABLE users ADD COLUMN IF NOT EXISTS batch varchar(255);
ALTER TABLE notice_targets ADD COLUMN IF NOT EXISTS division varchar(255);
ALTER TABLE notice_targets ADD COLUMN IF NOT EXISTS batch varchar(255);
ALTER TABLE notices ADD COLUMN IF NOT EXISTS state varchar(24) NOT NULL DEFAULT 'ACTIVE';

ALTER TABLE notices DROP CONSTRAINT IF EXISTS notices_category_check;
ALTER TABLE notices ADD CONSTRAINT notices_category_check
    CHECK (category IN ('GENERAL', 'EXAM', 'ASSIGNMENT', 'EVENT', 'PLACEMENT', 'FEES', 'FINANCE', 'WORKSHOP', 'HOLIDAY'));

UPDATE users
SET division = CASE
        WHEN role = 'ADMIN' THEN NULL
        WHEN department IN ('CSE', 'IT') AND id % 3 = 0 THEN 'C'
        WHEN id % 2 = 0 THEN 'A'
        ELSE 'B'
    END,
    batch = CASE
        WHEN role = 'ADMIN' THEN NULL
        WHEN department IN ('CSE', 'IT') AND id % 3 = 0 THEN 'C1'
        WHEN id % 2 = 0 THEN 'A1'
        ELSE 'B2'
    END
WHERE role = 'STUDENT'
   OR division IS NOT NULL
   OR batch IS NOT NULL;

WITH admin_user AS (
    SELECT id FROM users WHERE role = 'ADMIN' ORDER BY id LIMIT 1
),
seed(title, description, priority, category, pinned, created_offset, expiry_offset, state) AS (
    VALUES
    ('Urgent Exam Form Deadline - Final Call',
     'Students must verify exam form details and fee status before the deadline. Bring ID card for any correction requests.',
     'HIGH', 'EXAM', true, INTERVAL '4 hours', INTERVAL '45 minutes', 'ACTIVE'),
    ('Cloud Lab Assignment 5 Submission',
     'Upload the PDF report and Git repository link on LMS. Late submissions need mentor approval.',
     'HIGH', 'ASSIGNMENT', true, INTERVAL '8 hours', INTERVAL '3 hours', 'ACTIVE'),
    ('Placement Aptitude Test Slot Booking',
     'Eligible students should book their aptitude test slot and keep updated resumes ready for verification.',
     'HIGH', 'PLACEMENT', true, INTERVAL '1 day', INTERVAL '18 hours', 'ACTIVE'),
    ('Cybersecurity Workshop Registration',
     'Hands-on workshop covering threat modeling, password hygiene, and campus SOC case studies.',
     'MEDIUM', 'WORKSHOP', false, INTERVAL '2 days', INTERVAL '30 hours', 'ACTIVE'),
    ('Semester Midterm Timetable Published',
     'Department-wise midterm timetable is available. Students should check room allocation before reporting.',
     'HIGH', 'EXAM', true, INTERVAL '3 days', INTERVAL '6 days', 'ACTIVE'),
    ('AI Seminar by Industry Expert',
     'Guest seminar on applied generative AI workflows, responsible use, and internship preparation.',
     'MEDIUM', 'EVENT', false, INTERVAL '3 days', INTERVAL '9 days', 'ACTIVE'),
    ('Tuition Fee Installment Reminder',
     'Students with pending installment plans should clear dues through the accounts portal.',
     'HIGH', 'FINANCE', false, INTERVAL '5 days', INTERVAL '12 days', 'ACTIVE'),
    ('Innovation Club Hackathon Launch',
     'Teams of up to four can register for the weekend hackathon. Themes include campus automation and accessibility.',
     'MEDIUM', 'EVENT', false, INTERVAL '6 days', INTERVAL '17 days', 'ACTIVE'),
    ('Internship NOC Collection Window',
     'Students selected for summer internships can collect NOC letters from the department office.',
     'MEDIUM', 'PLACEMENT', false, INTERVAL '7 days', INTERVAL '22 days', 'ACTIVE'),
    ('Library Digital Resources Orientation',
     'Orientation for IEEE, ACM, Springer, and e-book access. Recommended for first-year students.',
     'LOW', 'GENERAL', false, INTERVAL '8 days', INTERVAL '27 days', 'ACTIVE'),
    ('Holiday Notice - Annual Cultural Day',
     'Regular classes remain suspended after 12:30 PM. Event rehearsals continue as per coordinator instructions.',
     'LOW', 'HOLIDAY', false, INTERVAL '9 days', INTERVAL '33 days', 'ACTIVE'),
    ('Project Review Rubric Archived Sample',
     'Archived demo notice retained for audit, analytics, and archive workflow demonstration.',
     'MEDIUM', 'ASSIGNMENT', false, INTERVAL '38 days', -INTERVAL '21 days', 'ARCHIVED'),
    ('Expired Lab Manual Correction Window',
     'Expired demo notice hidden from student active feeds but retained for analytics history.',
     'LOW', 'GENERAL', false, INTERVAL '12 days', -INTERVAL '2 days', 'EXPIRED')
)
INSERT INTO notices (title, description, priority, category, pinned, view_count, state, created_at, expiry_date, created_by)
SELECT seed.title, seed.description, seed.priority, seed.category, seed.pinned, 0, seed.state,
       NOW() - seed.created_offset, NOW() + seed.expiry_offset, admin_user.id
FROM seed
CROSS JOIN admin_user
WHERE NOT EXISTS (
    SELECT 1 FROM notices n WHERE n.title = seed.title
);

WITH target_data(title, department, year, division, batch) AS (
    VALUES
    ('Cloud Lab Assignment 5 Submission', 'CSE', 3, 'A', 'A1'),
    ('Cloud Lab Assignment 5 Submission', 'IT', 3, NULL, NULL),
    ('Placement Aptitude Test Slot Booking', 'CSE', 3, NULL, NULL),
    ('Placement Aptitude Test Slot Booking', 'IT', 3, NULL, NULL),
    ('Cybersecurity Workshop Registration', 'CSE', 2, 'A', NULL),
    ('Cybersecurity Workshop Registration', 'ECE', 3, NULL, NULL),
    ('Semester Midterm Timetable Published', 'CSE', 2, NULL, NULL),
    ('Semester Midterm Timetable Published', 'CSE', 3, NULL, NULL),
    ('AI Seminar by Industry Expert', 'ECE', 3, NULL, NULL),
    ('AI Seminar by Industry Expert', 'IT', 3, 'C', NULL),
    ('Innovation Club Hackathon Launch', 'CSE', 1, NULL, NULL),
    ('Innovation Club Hackathon Launch', 'IT', 2, NULL, NULL),
    ('Internship NOC Collection Window', 'IT', 2, NULL, NULL),
    ('Internship NOC Collection Window', 'ECE', 4, NULL, NULL),
    ('Library Digital Resources Orientation', 'CSE', 1, NULL, NULL),
    ('Project Review Rubric Archived Sample', 'CSE', 3, NULL, NULL),
    ('Expired Lab Manual Correction Window', 'CSE', 2, NULL, NULL)
)
INSERT INTO notice_targets (notice_id, department, year, division, batch)
SELECT n.id, t.department, t.year, t.division, t.batch
FROM target_data t
JOIN notices n ON n.title = t.title
WHERE NOT EXISTS (
    SELECT 1 FROM notice_targets nt
    WHERE nt.notice_id = n.id
      AND nt.department = t.department
      AND nt.year = t.year
      AND nt.division IS NOT DISTINCT FROM t.division
      AND nt.batch IS NOT DISTINCT FROM t.batch
);

WITH recipients AS (
    SELECT DISTINCT n.id AS notice_id, u.id AS user_id, n.title
    FROM notices n
    JOIN users u ON u.role = 'STUDENT'
    WHERE n.title IN (
        'Urgent Exam Form Deadline - Final Call',
        'Cloud Lab Assignment 5 Submission',
        'Placement Aptitude Test Slot Booking',
        'Cybersecurity Workshop Registration',
        'Semester Midterm Timetable Published',
        'AI Seminar by Industry Expert',
        'Tuition Fee Installment Reminder',
        'Innovation Club Hackathon Launch',
        'Internship NOC Collection Window',
        'Library Digital Resources Orientation',
        'Holiday Notice - Annual Cultural Day',
        'Project Review Rubric Archived Sample',
        'Expired Lab Manual Correction Window'
    )
      AND (
        NOT EXISTS (SELECT 1 FROM notice_targets nt WHERE nt.notice_id = n.id)
        OR EXISTS (
            SELECT 1 FROM notice_targets nt
            WHERE nt.notice_id = n.id
              AND nt.department = u.department
              AND nt.year = u.year
              AND (nt.division IS NULL OR u.division IS NULL OR nt.division = u.division)
              AND (nt.batch IS NULL OR u.batch IS NULL OR nt.batch = u.batch)
        )
      )
)
INSERT INTO notifications (user_id, notice_id, message, type, is_read, is_acknowledged, created_at)
SELECT r.user_id, r.notice_id, 'New notice published: ' || r.title, 'NORMAL',
       (r.user_id + r.notice_id) % 3 = 0,
       (r.user_id + r.notice_id) % 5 = 0,
       NOW() - (((r.user_id + r.notice_id) % 48) || ' hours')::interval
FROM recipients r
WHERE NOT EXISTS (
    SELECT 1 FROM notifications nf
    WHERE nf.user_id = r.user_id
      AND nf.notice_id = r.notice_id
      AND nf.type = 'NORMAL'
);

WITH recipients AS (
    SELECT DISTINCT n.id AS notice_id, u.id AS user_id
    FROM notices n
    JOIN users u ON u.role = 'STUDENT'
    WHERE n.title IN (
        'Urgent Exam Form Deadline - Final Call',
        'Cloud Lab Assignment 5 Submission',
        'Placement Aptitude Test Slot Booking',
        'Cybersecurity Workshop Registration',
        'Semester Midterm Timetable Published',
        'AI Seminar by Industry Expert',
        'Tuition Fee Installment Reminder',
        'Innovation Club Hackathon Launch',
        'Internship NOC Collection Window',
        'Library Digital Resources Orientation',
        'Holiday Notice - Annual Cultural Day',
        'Project Review Rubric Archived Sample',
        'Expired Lab Manual Correction Window'
    )
      AND (
        NOT EXISTS (SELECT 1 FROM notice_targets nt WHERE nt.notice_id = n.id)
        OR EXISTS (
            SELECT 1 FROM notice_targets nt
            WHERE nt.notice_id = n.id
              AND nt.department = u.department
              AND nt.year = u.year
              AND (nt.division IS NULL OR u.division IS NULL OR nt.division = u.division)
              AND (nt.batch IS NULL OR u.batch IS NULL OR nt.batch = u.batch)
        )
      )
)
INSERT INTO notice_status (user_id, notice_id, is_read, is_acknowledged, viewed)
SELECT r.user_id, r.notice_id,
       (r.user_id + r.notice_id) % 3 = 0,
       (r.user_id + r.notice_id) % 5 = 0,
       (r.user_id + r.notice_id) % 2 = 0
FROM recipients r
WHERE NOT EXISTS (
    SELECT 1 FROM notice_status ns
    WHERE ns.user_id = r.user_id
      AND ns.notice_id = r.notice_id
);

WITH seed_notices AS (
    SELECT id
    FROM notices
    WHERE title IN (
        'Urgent Exam Form Deadline - Final Call',
        'Cloud Lab Assignment 5 Submission',
        'Placement Aptitude Test Slot Booking',
        'Cybersecurity Workshop Registration',
        'Semester Midterm Timetable Published',
        'AI Seminar by Industry Expert',
        'Tuition Fee Installment Reminder',
        'Innovation Club Hackathon Launch',
        'Internship NOC Collection Window',
        'Library Digital Resources Orientation',
        'Holiday Notice - Annual Cultural Day',
        'Project Review Rubric Archived Sample',
        'Expired Lab Manual Correction Window'
    )
),
visible_recipients AS (
    SELECT DISTINCT n.id AS notice_id, u.id AS user_id
    FROM notices n
    JOIN users u ON u.role = 'STUDENT'
    WHERE n.id IN (SELECT id FROM seed_notices)
      AND (
        NOT EXISTS (SELECT 1 FROM notice_targets nt WHERE nt.notice_id = n.id)
        OR EXISTS (
            SELECT 1 FROM notice_targets nt
            WHERE nt.notice_id = n.id
              AND nt.department = u.department
              AND nt.year = u.year
              AND (nt.division IS NULL OR u.division IS NULL OR nt.division = u.division)
              AND (nt.batch IS NULL OR u.batch IS NULL OR nt.batch = u.batch)
        )
      )
)
DELETE FROM notice_status ns
USING seed_notices sn
WHERE ns.notice_id = sn.id
  AND NOT EXISTS (
      SELECT 1
      FROM visible_recipients vr
      WHERE vr.notice_id = ns.notice_id
        AND vr.user_id = ns.user_id
  );

UPDATE notifications nf
SET is_read = true
WHERE is_acknowledged = true;

UPDATE notice_status ns
SET is_read = true, viewed = true
WHERE is_acknowledged = true;

WITH reply_data(title, email, message, hours_ago) AS (
    VALUES
    ('Cloud Lab Assignment 5 Submission', 'rahul.cse3@test.com', 'Submitted the repository link and PDF report on LMS.', 4),
    ('Placement Aptitude Test Slot Booking', 'priya.cse3@test.com', 'Booked afternoon slot and uploaded updated resume.', 6),
    ('Cybersecurity Workshop Registration', 'rohan@test.com', 'Registered for workshop. Please confirm lab number.', 8),
    ('Semester Midterm Timetable Published', 'amit@test.com', 'Timetable checked. No clash for my elective subject.', 12),
    ('AI Seminar by Industry Expert', 'farah.ece3@test.com', 'Interested in attending and receiving certificate.', 16),
    ('Innovation Club Hackathon Launch', 'meera.cse1@test.com', 'Team registered for campus automation track.', 18),
    ('Internship NOC Collection Window', 'kavya.it2@test.com', 'NOC collected from office today.', 22),
    ('Tuition Fee Installment Reminder', 'sneha@test.com', 'Payment completed and receipt uploaded.', 26)
)
INSERT INTO notice_replies (notice_id, user_id, message, created_at)
SELECT n.id, u.id, r.message, NOW() - (r.hours_ago || ' hours')::interval
FROM reply_data r
JOIN notices n ON n.title = r.title
JOIN users u ON u.email = r.email
WHERE NOT EXISTS (
    SELECT 1 FROM notice_replies nr
    WHERE nr.notice_id = n.id
      AND nr.user_id = u.id
      AND nr.message = r.message
);

UPDATE notices n
SET view_count = COALESCE(v.views, 0)
FROM (
    SELECT notice_id, COUNT(*) AS views
    FROM notice_status
    WHERE viewed = true
    GROUP BY notice_id
) v
WHERE n.id = v.notice_id;

SELECT setval(pg_get_serial_sequence('users', 'id'), COALESCE((SELECT MAX(id) FROM users), 1));
SELECT setval(pg_get_serial_sequence('notices', 'id'), COALESCE((SELECT MAX(id) FROM notices), 1));
SELECT setval(pg_get_serial_sequence('notice_targets', 'id'), COALESCE((SELECT MAX(id) FROM notice_targets), 1));
SELECT setval(pg_get_serial_sequence('notifications', 'id'), COALESCE((SELECT MAX(id) FROM notifications), 1));
SELECT setval(pg_get_serial_sequence('notice_status', 'id'), COALESCE((SELECT MAX(id) FROM notice_status), 1));
SELECT setval(pg_get_serial_sequence('notice_replies', 'id'), COALESCE((SELECT MAX(id) FROM notice_replies), 1));

COMMIT;
