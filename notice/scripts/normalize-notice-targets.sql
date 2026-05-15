-- Focused notice target normalization.
-- Converts department/year target shorthand into explicit realistic division/batch rows
-- based on the current student distribution. True global notices remain represented by
-- having no notice_targets rows.

BEGIN;

CREATE TEMP TABLE normalized_notice_targets ON COMMIT DROP AS
WITH current_targets AS (
    SELECT nt.notice_id, nt.department, nt.year, nt.division, nt.batch
    FROM notice_targets nt
),
matched_students AS (
    SELECT DISTINCT
           t.notice_id,
           u.department,
           u.year,
           u.division,
           u.batch
    FROM current_targets t
    JOIN users u
      ON u.role = 'STUDENT'
     AND u.department = t.department
     AND u.year = t.year
     AND (t.division IS NULL OR u.division = t.division)
     AND (t.batch IS NULL OR u.batch = t.batch)
),
fallback_students AS (
    SELECT DISTINCT
           t.notice_id,
           u.department,
           u.year,
           u.division,
           u.batch
    FROM current_targets t
    JOIN users u
      ON u.role = 'STUDENT'
     AND u.department = t.department
     AND u.year = t.year
    WHERE NOT EXISTS (
        SELECT 1
        FROM matched_students ms
        WHERE ms.notice_id = t.notice_id
          AND ms.department = t.department
          AND ms.year = t.year
    )
)
SELECT DISTINCT notice_id, department, year, division, batch
FROM matched_students
UNION
SELECT DISTINCT notice_id, department, year, division, batch
FROM fallback_students;

DELETE FROM notice_targets;

INSERT INTO notice_targets (notice_id, department, year, division, batch)
SELECT notice_id, department, year, division, batch
FROM normalized_notice_targets
ORDER BY notice_id, department, year, division, batch;

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
          AND nt.division = u.division
          AND nt.batch = u.batch
    );

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

SELECT setval(pg_get_serial_sequence('notice_targets', 'id'), COALESCE((SELECT MAX(id) FROM notice_targets), 1));
SELECT setval(pg_get_serial_sequence('notifications', 'id'), COALESCE((SELECT MAX(id) FROM notifications), 1));
SELECT setval(pg_get_serial_sequence('notice_status', 'id'), COALESCE((SELECT MAX(id) FROM notice_status), 1));

COMMIT;
