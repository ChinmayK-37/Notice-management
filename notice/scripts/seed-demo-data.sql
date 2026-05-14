-- Demo seed for Notice Circular Management (PostgreSQL).
-- Run: psql -U postgres -d college_notice -f scripts/seed-demo-data.sql
-- Password for all demo accounts: password
-- (BCrypt hash below matches Spring BCryptPasswordEncoder / common test hash.)

BEGIN;

TRUNCATE TABLE notifications, notice_status, notice_targets, notices, users RESTART IDENTITY CASCADE;

INSERT INTO users (id, name, email, password, role, department, year) VALUES
  (1, 'Dr. Meera Joshi', 'admin@college.edu',
   '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
   'ADMIN', 'Administration', 1),
  (2, 'Priya Sharma', 'priya.sharma@college.edu',
   '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
   'STUDENT', 'CSE', 2),
  (3, 'Rahul Kapoor', 'rahul.kapoor@college.edu',
   '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
   'STUDENT', 'CSE', 2),
  (4, 'Ananya Iyer', 'ananya.iyer@college.edu',
   '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
   'STUDENT', 'ECE', 3),
  (5, 'Vikram Singh', 'vikram.singh@college.edu',
   '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
   'STUDENT', 'ME', 4),
  (6, 'Sneha Kaul', 'sneha.kaul@college.edu',
   '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
   'STUDENT', 'CSE', 3);

SELECT setval(pg_get_serial_sequence('users', 'id'), (SELECT MAX(id) FROM users));

-- Notices: varied priority, dates, audiences
INSERT INTO notices (id, title, description, priority, created_at, expiry_date, created_by) VALUES
(1, 'End-Semester Examination Schedule',
 'Theory exams begin 08:30. Carry college ID and hall ticket. See attached timetable on portal.',
 'HIGH', NOW() - INTERVAL '6 days', NOW() + INTERVAL '34 days', 1),
(2, 'Republic Day Holiday — Campus Closed',
 'All departments closed. Hostel mess runs reduced hours on 26 Jan only.',
 'LOW', NOW() - INTERVAL '2 days', NOW() + INTERVAL '75 days', 1),
(3, 'Hands-on Flutter Workshop (ECE)',
 'Bring laptops with Flutter SDK. Limited seats — register by deadline.',
 'MEDIUM', NOW() - INTERVAL '4 days', NOW() + INTERVAL '16 days', 1),
(4, 'Campus Placement Drive — Tier-1 Companies',
 'Resume upload mandatory. Dress code: business formals. Mock interviews in Annex.',
 'HIGH', NOW() - INTERVAL '3 days', NOW() + INTERVAL '11 days', 1),
(5, 'Tuition Fee — Semester II Due',
 'Pay online via portal to avoid late fee. Contact accounts for instalment plans.',
 'HIGH', NOW() - INTERVAL '1 day', NOW() + INTERVAL '9 days', 1),
(6, 'Operating Systems — Assignment 3 (Past Due)',
 'Submission was via LMS. Late penalty applies per policy. Contact TA for disputes.',
 'MEDIUM', NOW() - INTERVAL '20 days', NOW() - INTERVAL '4 days', 1),
(7, 'Annual Sports Meet — Registration Open',
 'Track and field, badminton, chess. House captains collect names by Friday.',
 'LOW', NOW() - INTERVAL '5 days', NOW() + INTERVAL '28 days', 1),
(8, 'Library — Winter Vacation Hours',
 'Issue desk closes early during vacation week. Digital resources remain 24x7.',
 'LOW', NOW() - INTERVAL '30 days', NOW() - INTERVAL '10 days', 1),
(9, 'URGENT: CS302 Exam Venue Changed',
 'Hall A → Hall C (Block 2). Arrive 20 minutes early for seating verification.',
 'HIGH', NOW() - INTERVAL '8 hours', NOW() + INTERVAL '40 hours', 1),
(10, 'AI Research Seminar — Guest Lecture',
 'Prof. Rao (IISc). Open to ECE and allied branches. E-certificate for attendees.',
 'MEDIUM', NOW() - INTERVAL '7 days', NOW() + INTERVAL '12 days', 1),
(11, 'Industrial Visit — Manufacturing Lab',
 'Safety shoes mandatory. Bus leaves main gate 07:15 sharp.',
 'MEDIUM', NOW() - INTERVAL '9 days', NOW() + INTERVAL '48 days', 1),
(12, 'Merit-cum-Means Scholarship — CSE Year 3',
 'Income certificate and previous semester marksheet required. Apply on portal.',
 'MEDIUM', NOW() - INTERVAL '6 days', NOW() + INTERVAL '22 days', 1);

SELECT setval(pg_get_serial_sequence('notices', 'id'), (SELECT MAX(id) FROM notices));

-- Targets (empty = all students + admin per app logic; here explicit rows where needed)
INSERT INTO notice_targets (id, notice_id, department, year) VALUES
  (1, 1, 'CSE', 2),
  (2, 3, 'ECE', 3),
  (3, 4, 'CSE', 2),
  (4, 4, 'ME', 4),
  (5, 6, 'CSE', 2),
  (6, 9, 'CSE', 2),
  (7, 10, 'ECE', 3),
  (8, 12, 'CSE', 3);
-- Notices 2,5,7,8,11 have no targets → all users (1–6)

SELECT setval(pg_get_serial_sequence('notice_targets', 'id'), (SELECT MAX(id) FROM notice_targets));

-- Helper: one NORMAL notification + matching notice_status per (user, notice)
-- N1 → users 2,3
INSERT INTO notifications (user_id, notice_id, message, type, is_read, is_acknowledged, created_at) VALUES
 (2, 1, 'New notice published: End-Semester Examination Schedule', 'NORMAL', true, true, NOW() - INTERVAL '5 days'),
 (3, 1, 'New notice published: End-Semester Examination Schedule', 'NORMAL', false, false, NOW() - INTERVAL '5 days');
INSERT INTO notice_status (user_id, notice_id, is_read, is_acknowledged) VALUES
 (2, 1, true, true), (3, 1, false, false);

-- N2 global → 1..6
INSERT INTO notifications (user_id, notice_id, message, type, is_read, is_acknowledged, created_at) VALUES
 (1, 2, 'New notice published: Republic Day Holiday — Campus Closed', 'NORMAL', true, false, NOW() - INTERVAL '1 day'),
 (2, 2, 'New notice published: Republic Day Holiday — Campus Closed', 'NORMAL', true, true, NOW() - INTERVAL '1 day'),
 (3, 2, 'New notice published: Republic Day Holiday — Campus Closed', 'NORMAL', false, false, NOW() - INTERVAL '1 day'),
 (4, 2, 'New notice published: Republic Day Holiday — Campus Closed', 'NORMAL', true, false, NOW() - INTERVAL '1 day'),
 (5, 2, 'New notice published: Republic Day Holiday — Campus Closed', 'NORMAL', false, true, NOW() - INTERVAL '1 day'),
 (6, 2, 'New notice published: Republic Day Holiday — Campus Closed', 'NORMAL', false, false, NOW() - INTERVAL '1 day');
INSERT INTO notice_status (user_id, notice_id, is_read, is_acknowledged) VALUES
 (1, 2, true, false), (2, 2, true, true), (3, 2, false, false), (4, 2, true, false), (5, 2, false, true), (6, 2, false, false);

-- N3 → user 4
INSERT INTO notifications (user_id, notice_id, message, type, is_read, is_acknowledged, created_at) VALUES
 (4, 3, 'New notice published: Hands-on Flutter Workshop (ECE)', 'NORMAL', true, false, NOW() - INTERVAL '3 days');
INSERT INTO notice_status (user_id, notice_id, is_read, is_acknowledged) VALUES (4, 3, true, false);

-- N4 → 2,3,5
INSERT INTO notifications (user_id, notice_id, message, type, is_read, is_acknowledged, created_at) VALUES
 (2, 4, 'New notice published: Campus Placement Drive — Tier-1 Companies', 'NORMAL', true, true, NOW() - INTERVAL '2 days'),
 (3, 4, 'New notice published: Campus Placement Drive — Tier-1 Companies', 'NORMAL', true, false, NOW() - INTERVAL '2 days'),
 (5, 4, 'New notice published: Campus Placement Drive — Tier-1 Companies', 'NORMAL', false, false, NOW() - INTERVAL '2 days');
INSERT INTO notice_status (user_id, notice_id, is_read, is_acknowledged) VALUES
 (2, 4, true, true), (3, 4, true, false), (5, 4, false, false);

-- N5 global fee
INSERT INTO notifications (user_id, notice_id, message, type, is_read, is_acknowledged, created_at) VALUES
 (1, 5, 'New notice published: Tuition Fee — Semester II Due', 'NORMAL', false, false, NOW() - INTERVAL '12 hours'),
 (2, 5, 'New notice published: Tuition Fee — Semester II Due', 'NORMAL', true, false, NOW() - INTERVAL '12 hours'),
 (3, 5, 'New notice published: Tuition Fee — Semester II Due', 'NORMAL', true, true, NOW() - INTERVAL '12 hours'),
 (4, 5, 'New notice published: Tuition Fee — Semester II Due', 'NORMAL', false, false, NOW() - INTERVAL '12 hours'),
 (5, 5, 'New notice published: Tuition Fee — Semester II Due', 'NORMAL', true, false, NOW() - INTERVAL '12 hours'),
 (6, 5, 'New notice published: Tuition Fee — Semester II Due', 'NORMAL', false, false, NOW() - INTERVAL '12 hours');
INSERT INTO notice_status (user_id, notice_id, is_read, is_acknowledged) VALUES
 (1, 5, false, false), (2, 5, true, false), (3, 5, true, true), (4, 5, false, false), (5, 5, true, false), (6, 5, false, false);

-- N6 CSE2 expired assignment
INSERT INTO notifications (user_id, notice_id, message, type, is_read, is_acknowledged, created_at) VALUES
 (2, 6, 'New notice published: Operating Systems — Assignment 3 (Past Due)', 'NORMAL', true, true, NOW() - INTERVAL '18 days'),
 (3, 6, 'New notice published: Operating Systems — Assignment 3 (Past Due)', 'NORMAL', true, false, NOW() - INTERVAL '18 days');
INSERT INTO notice_status (user_id, notice_id, is_read, is_acknowledged) VALUES
 (2, 6, true, true), (3, 6, true, false);

-- N7 global sports
INSERT INTO notifications (user_id, notice_id, message, type, is_read, is_acknowledged, created_at) VALUES
 (1, 7, 'New notice published: Annual Sports Meet — Registration Open', 'NORMAL', true, true, NOW() - INTERVAL '4 days'),
 (2, 7, 'New notice published: Annual Sports Meet — Registration Open', 'NORMAL', false, false, NOW() - INTERVAL '4 days'),
 (3, 7, 'New notice published: Annual Sports Meet — Registration Open', 'NORMAL', true, false, NOW() - INTERVAL '4 days'),
 (4, 7, 'New notice published: Annual Sports Meet — Registration Open', 'NORMAL', false, false, NOW() - INTERVAL '4 days'),
 (5, 7, 'New notice published: Annual Sports Meet — Registration Open', 'NORMAL', true, true, NOW() - INTERVAL '4 days'),
 (6, 7, 'New notice published: Annual Sports Meet — Registration Open', 'NORMAL', false, false, NOW() - INTERVAL '4 days');
INSERT INTO notice_status (user_id, notice_id, is_read, is_acknowledged) VALUES
 (1, 7, true, true), (2, 7, false, false), (3, 7, true, false), (4, 7, false, false), (5, 7, true, true), (6, 7, false, false);

-- N8 global library expired
INSERT INTO notifications (user_id, notice_id, message, type, is_read, is_acknowledged, created_at) VALUES
 (1, 8, 'New notice published: Library — Winter Vacation Hours', 'NORMAL', true, false, NOW() - INTERVAL '25 days'),
 (2, 8, 'New notice published: Library — Winter Vacation Hours', 'NORMAL', true, true, NOW() - INTERVAL '25 days'),
 (3, 8, 'New notice published: Library — Winter Vacation Hours', 'NORMAL', false, false, NOW() - INTERVAL '25 days'),
 (4, 8, 'New notice published: Library — Winter Vacation Hours', 'NORMAL', true, true, NOW() - INTERVAL '25 days'),
 (5, 8, 'New notice published: Library — Winter Vacation Hours', 'NORMAL', false, false, NOW() - INTERVAL '25 days'),
 (6, 8, 'New notice published: Library — Winter Vacation Hours', 'NORMAL', true, false, NOW() - INTERVAL '25 days');
INSERT INTO notice_status (user_id, notice_id, is_read, is_acknowledged) VALUES
 (1, 8, true, false), (2, 8, true, true), (3, 8, false, false), (4, 8, true, true), (5, 8, false, false), (6, 8, true, false);

-- N9 urgent CSE2
INSERT INTO notifications (user_id, notice_id, message, type, is_read, is_acknowledged, created_at) VALUES
 (2, 9, 'New notice published: URGENT: CS302 Exam Venue Changed', 'NORMAL', false, false, NOW() - INTERVAL '6 hours'),
 (3, 9, 'New notice published: URGENT: CS302 Exam Venue Changed', 'NORMAL', true, false, NOW() - INTERVAL '6 hours');
INSERT INTO notice_status (user_id, notice_id, is_read, is_acknowledged) VALUES
 (2, 9, false, false), (3, 9, true, false);

-- N10 ECE3 seminar
INSERT INTO notifications (user_id, notice_id, message, type, is_read, is_acknowledged, created_at) VALUES
 (4, 10, 'New notice published: AI Research Seminar — Guest Lecture', 'NORMAL', false, false, NOW() - INTERVAL '5 days');
INSERT INTO notice_status (user_id, notice_id, is_read, is_acknowledged) VALUES (4, 10, false, false);

-- N11 global industrial visit
INSERT INTO notifications (user_id, notice_id, message, type, is_read, is_acknowledged, created_at) VALUES
 (1, 11, 'New notice published: Industrial Visit — Manufacturing Lab', 'NORMAL', true, true, NOW() - INTERVAL '8 days'),
 (2, 11, 'New notice published: Industrial Visit — Manufacturing Lab', 'NORMAL', true, false, NOW() - INTERVAL '8 days'),
 (3, 11, 'New notice published: Industrial Visit — Manufacturing Lab', 'NORMAL', false, true, NOW() - INTERVAL '8 days'),
 (4, 11, 'New notice published: Industrial Visit — Manufacturing Lab', 'NORMAL', true, true, NOW() - INTERVAL '8 days'),
 (5, 11, 'New notice published: Industrial Visit — Manufacturing Lab', 'NORMAL', false, false, NOW() - INTERVAL '8 days'),
 (6, 11, 'New notice published: Industrial Visit — Manufacturing Lab', 'NORMAL', true, false, NOW() - INTERVAL '8 days');
INSERT INTO notice_status (user_id, notice_id, is_read, is_acknowledged) VALUES
 (1, 11, true, true), (2, 11, true, false), (3, 11, false, true), (4, 11, true, true), (5, 11, false, false), (6, 11, true, false);

-- N12 CSE3 scholarship → user 6
INSERT INTO notifications (user_id, notice_id, message, type, is_read, is_acknowledged, created_at) VALUES
 (6, 12, 'New notice published: Merit-cum-Means Scholarship — CSE Year 3', 'NORMAL', true, false, NOW() - INTERVAL '4 days');
INSERT INTO notice_status (user_id, notice_id, is_read, is_acknowledged) VALUES (6, 12, true, false);

-- Sample REMINDER rows (optional demo of second type)
INSERT INTO notifications (user_id, notice_id, message, type, is_read, is_acknowledged, created_at) VALUES
 (2, 5, 'Reminder: Tuition Fee — Semester II Due deadline approaching', 'REMINDER', false, false, NOW() - INTERVAL '2 hours'),
 (3, 9, 'Reminder: URGENT: CS302 Exam Venue Changed deadline approaching', 'REMINDER', false, false, NOW() - INTERVAL '1 hours');

SELECT setval(pg_get_serial_sequence('notifications', 'id'), (SELECT MAX(id) FROM notifications));
SELECT setval(pg_get_serial_sequence('notice_status', 'id'), (SELECT MAX(id) FROM notice_status));

COMMIT;
