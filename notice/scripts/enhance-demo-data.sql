-- Safe demo enrichment for workflow polish features.
-- Run from the backend folder:
-- psql -U postgres -d college_notice -f scripts/enhance-demo-data.sql

BEGIN;

ALTER TABLE notices DROP CONSTRAINT IF EXISTS notices_category_check;
ALTER TABLE notices ADD CONSTRAINT notices_category_check
    CHECK (category IN ('GENERAL', 'EXAM', 'ASSIGNMENT', 'EVENT', 'PLACEMENT', 'FEES', 'FINANCE', 'WORKSHOP', 'HOLIDAY'));

UPDATE notices
SET category = CASE
    WHEN lower(title) LIKE '%exam%' OR lower(title) LIKE '%viva%' OR lower(title) LIKE '%hall ticket%' THEN 'EXAM'
    WHEN lower(title) LIKE '%assignment%' OR lower(title) LIKE '%project%' OR lower(title) LIKE '%submission%' THEN 'ASSIGNMENT'
    WHEN lower(title) LIKE '%placement%' OR lower(title) LIKE '%internship%' THEN 'PLACEMENT'
    WHEN lower(title) LIKE '%fee%' OR lower(title) LIKE '%scholarship%' THEN 'FINANCE'
    WHEN lower(title) LIKE '%workshop%' THEN 'WORKSHOP'
    WHEN lower(title) LIKE '%holiday%' THEN 'HOLIDAY'
    WHEN lower(title) LIKE '%sports%' OR lower(title) LIKE '%techfest%' OR lower(title) LIKE '%hackathon%' THEN 'EVENT'
    ELSE COALESCE(NULLIF(category, ''), 'GENERAL')
END;

UPDATE notices
SET pinned = title IN (
    'Urgent Exam Form Deadline',
    'Urgent Hall Ticket Verification Deadline',
    'Campus Placement Drive - Infosys',
    'Final Semester Exam Timetable Released',
    'Mini project presentation'
);

UPDATE notice_status
SET viewed = true
WHERE is_read = true OR is_acknowledged = true;

UPDATE notice_status ns
SET viewed = true
FROM notices n
WHERE ns.notice_id = n.id
  AND n.priority = 'HIGH'
  AND ns.user_id IN (
      SELECT id FROM users WHERE role = 'STUDENT' ORDER BY id LIMIT 8
  );

INSERT INTO notice_replies (notice_id, user_id, message, created_at)
SELECT n.id, u.id, v.message, NOW() - (v.hours_ago || ' hours')::interval
FROM (VALUES
    ('Urgent Exam Form Deadline', 'rahul@test.com', 'I have submitted the exam form and payment receipt.', 2),
    ('Urgent Hall Ticket Verification Deadline', 'priya.cse3@test.com', 'Hall ticket details verified. No corrections required.', 3),
    ('Campus Placement Drive - Infosys', 'rahul.cse3@test.com', 'Resume uploaded. Please confirm if aptitude slot is morning batch.', 7),
    ('Database Systems Assignment Submission', 'amit@test.com', 'Assignment submitted on LMS. Screenshot retained for proof.', 9),
    ('AI and Cloud Workshop', 'farah.ece3@test.com', 'Registered for the workshop and installed required tools.', 11),
    ('Annual TechFest Registration Open', 'sahil.it3@test.com', 'Team registration completed for hackathon track.', 14),
    ('Mini Project Review 2 Schedule', 'meera.cse1@test.com', 'Project report draft is ready for review.', 18),
    ('Scholarship Document Upload Window', 'ananya.ece4@test.com', 'Income certificate uploaded. Awaiting verification.', 20),
    ('Internship NOC Collection', 'kavya.it2@test.com', 'NOC collected from department office today.', 23),
    ('Sports Day Volunteer Registration', 'sneha@test.com', 'Volunteering for registration desk and logistics.', 28)
) AS v(title, email, message, hours_ago)
JOIN notices n ON n.title = v.title
JOIN users u ON u.email = v.email
WHERE NOT EXISTS (
    SELECT 1
    FROM notice_replies r
    WHERE r.notice_id = n.id
      AND r.user_id = u.id
      AND r.message = v.message
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

SELECT setval(pg_get_serial_sequence('notice_replies', 'id'), COALESCE((SELECT MAX(id) FROM notice_replies), 1));

COMMIT;
