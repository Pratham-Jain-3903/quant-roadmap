-- Fix schedule times: stored as UTC but should be IST
-- Delete existing schedule entries
DELETE FROM schedule;

-- Re-insert with explicit IST timestamps
-- The data here uses IST times stored as TIMESTAMPTZ
-- We use TIMESTAMP WITH TIME ZONE 'IST' so PostgreSQL stores correct UTC

DO $$
DECLARE
  rec RECORD;
  session_date DATE;
  session_start TIME;
  session_end TIME;
  color_val TEXT;
BEGIN
  FOR rec IN
    SELECT * FROM (VALUES
      ('2026-03-10', 'BSQT 1', 'BSQT 2', NULL, NULL),
      ('2026-03-12', 'FIAC 1', 'FIAC 2', NULL, NULL),
      ('2026-03-14', 'FIAC 3', 'FIAC 4', NULL, NULL),
      ('2026-03-17', 'BSQT 3', 'BSQT 4', NULL, NULL),
      ('2026-03-19', 'BSQT 5', 'BSQT 6', NULL, NULL),
      ('2026-03-21', 'FIAC 5', 'FIAC 6', NULL, NULL),
      ('2026-03-22', 'FIAC 7', 'FIAC 8', NULL, NULL),
      ('2026-03-24', 'FIAC 9', 'FIAC 10', NULL, NULL),
      ('2026-03-26', 'MKMT 1', 'MKMT 2', NULL, NULL),
      ('2026-03-28', 'MKMT 3', 'MKMT 4', NULL, NULL),
      ('2026-03-29', 'FIAC 11', 'FIAC 12', NULL, NULL),
      ('2026-03-31', 'MAEC 1', 'MAEC 2', NULL, NULL),
      ('2026-04-02', 'BSQT 7', 'BSQT 8', NULL, NULL),
      ('2026-04-04', 'FIAC 13', 'FIAC 14', NULL, NULL),
      ('2026-04-07', 'BSQT 9', 'BSQT 10', NULL, NULL),
      ('2026-04-09', 'Free Slot', 'Free Slot', NULL, NULL),
      ('2026-04-11', 'ORBE 1', 'ORBE 2', 'ORBE 1?', NULL),
      ('2026-04-12', 'FIAC 15', 'FIAC 16', NULL, NULL),
      ('2026-04-14', 'MAEC 3', 'MAEC 4', NULL, NULL),
      ('2026-04-16', 'MKMT 5', 'MKMT 6', NULL, NULL),
      ('2026-04-18', 'FIAC 17', 'FIAC 18', NULL, NULL),
      ('2026-04-19', 'BSQT 11', 'BSQT 12', NULL, NULL),
      ('2026-04-21', 'MKMT 7', 'MKMT 8', NULL, NULL),
      ('2026-04-23', 'MAEC 5', 'MAEC 6', NULL, NULL),
      ('2026-04-26', 'ORBE 3', 'ORBE 4', NULL, NULL),
      ('2026-04-30', 'MKMT 9', 'MKMT 10', NULL, NULL),
      ('2026-05-02', 'FIAC 19', 'FIAC 20', NULL, NULL),
      ('2026-05-03', 'BSQT 13', 'BSQT 14', 'ORBE 5', 'ORBE 6'),
      ('2026-05-07', 'ORBE 7', 'ORBE 8', NULL, NULL),
      ('2026-05-09', 'ORBE 9', 'ORBE 10', NULL, NULL),
      ('2026-05-10', 'BSQT 15', 'BSQT 16', 'IDD 9', 'IDD 10'),
      ('2026-05-14', 'ORBE 11', 'ORBE 12', NULL, NULL),
      ('2026-05-16', 'BSQT 17', 'BSQT 18', NULL, NULL),
      ('2026-05-19', 'BSQT 19', 'BSQT 20', NULL, NULL),
      ('2026-05-21', 'ORBE 13', 'ORBE 14', NULL, NULL),
      ('2026-05-23', 'MAEC 7', 'MAEC 8', NULL, NULL),
      ('2026-05-24', 'MAEC 9', 'MAEC 10', 'Free Slot', 'Free Slot'),
      ('2026-05-26', 'MAEC 11', 'MAEC 12', NULL, NULL),
      ('2026-05-28', 'MKMT 11', 'MKMT 12', NULL, NULL),
      ('2026-05-30', 'MKMT 13', 'MKMT 14', NULL, NULL),
      ('2026-05-31', 'MAEC 13', 'MAEC 14', 'Free Slot', 'Free Slot'),
      ('2026-06-02', 'MAEC 15', 'MAEC 16', NULL, NULL),
      ('2026-06-04', 'ORBE 15', 'ORBE 16', NULL, NULL),
      ('2026-06-06', 'MKMT 15', 'MKMT 16', NULL, NULL),
      ('2026-06-07', 'MAEC 17', 'MAEC 18', 'ORBE 17', 'ORBE 18'),
      ('2026-06-09', 'MKMT 17', 'MKMT 18', NULL, NULL),
      ('2026-06-11', 'MKMT 19', 'MKMT 20', NULL, NULL),
      ('2026-06-13', 'MAEC 19', 'MAEC 20', NULL, NULL),
      ('2026-06-14', 'ORBE 19', 'ORBE 20', NULL, NULL)
    ) AS d(date_val, s1, s2, s3, s4)
  LOOP
    session_date := rec.date_val::DATE;

    IF rec.s1 IS NOT NULL THEN
      IF rec.s1 LIKE 'BSQT%' THEN color_val := '#e74c3c';
      ELSIF rec.s1 LIKE 'FIAC%' THEN color_val := '#3498db';
      ELSIF rec.s1 LIKE 'MKMT%' THEN color_val := '#2ecc71';
      ELSIF rec.s1 LIKE 'MAEC%' THEN color_val := '#f39c12';
      ELSIF rec.s1 LIKE 'ORBE%' THEN color_val := '#9b59b6';
      ELSIF rec.s1 LIKE 'IDD%' THEN color_val := '#1abc9c';
      ELSE color_val := '#95a5a6';
      END IF;
    END IF;

    -- Session 1: 6:15-7:15 PM IST = 12:45-13:45 UTC
    IF rec.s1 IS NOT NULL AND rec.s1 != 'Free Slot' THEN
      INSERT INTO schedule (title, description, category, subject, start_time, end_time, color)
      VALUES (rec.s1, 'MBA Class - ' || rec.s1, 'MBA Class',
              CASE
                WHEN rec.s1 LIKE 'BSQT%' THEN 'BSQT'
                WHEN rec.s1 LIKE 'FIAC%' THEN 'FIAC'
                WHEN rec.s1 LIKE 'MKMT%' THEN 'MKMT'
                WHEN rec.s1 LIKE 'MAEC%' THEN 'MAEC'
                WHEN rec.s1 LIKE 'ORBE%' THEN 'ORBE'
                WHEN rec.s1 LIKE 'IDD%' THEN 'IDD'
                ELSE 'Other'
              END,
              (session_date + TIME '12:45:00') AT TIME ZONE 'UTC',
              (session_date + TIME '13:45:00') AT TIME ZONE 'UTC',
              color_val);
    END IF;

    -- Session 2: 7:30-8:30 PM IST = 14:00-15:00 UTC
    IF rec.s2 IS NOT NULL AND rec.s2 != 'Free Slot' THEN
      INSERT INTO schedule (title, description, category, subject, start_time, end_time, color)
      VALUES (rec.s2, 'MBA Class - ' || rec.s2, 'MBA Class',
              CASE
                WHEN rec.s2 LIKE 'BSQT%' THEN 'BSQT'
                WHEN rec.s2 LIKE 'FIAC%' THEN 'FIAC'
                WHEN rec.s2 LIKE 'MKMT%' THEN 'MKMT'
                WHEN rec.s2 LIKE 'MAEC%' THEN 'MAEC'
                WHEN rec.s2 LIKE 'ORBE%' THEN 'ORBE'
                WHEN rec.s2 LIKE 'IDD%' THEN 'IDD'
                ELSE 'Other'
              END,
              (session_date + TIME '14:00:00') AT TIME ZONE 'UTC',
              (session_date + TIME '15:00:00') AT TIME ZONE 'UTC',
              color_val);
    END IF;

    -- Session 3 (Sunday): 2:15-3:15 PM IST = 08:45-09:45 UTC
    IF rec.s3 IS NOT NULL AND rec.s3 != 'Free Slot' THEN
      INSERT INTO schedule (title, description, category, subject, start_time, end_time, color)
      VALUES (rec.s3, 'MBA Class - ' || rec.s3, 'MBA Class',
              CASE
                WHEN rec.s3 LIKE 'BSQT%' THEN 'BSQT'
                WHEN rec.s3 LIKE 'FIAC%' THEN 'FIAC'
                WHEN rec.s3 LIKE 'MKMT%' THEN 'MKMT'
                WHEN rec.s3 LIKE 'MAEC%' THEN 'MAEC'
                WHEN rec.s3 LIKE 'ORBE%' THEN 'ORBE'
                WHEN rec.s3 LIKE 'IDD%' THEN 'IDD'
                ELSE 'Other'
              END,
              (session_date + TIME '08:45:00') AT TIME ZONE 'UTC',
              (session_date + TIME '09:45:00') AT TIME ZONE 'UTC',
              color_val);
    END IF;

    -- Session 4 (Sunday): 3:30-4:30 PM IST = 10:00-11:00 UTC
    IF rec.s4 IS NOT NULL AND rec.s4 != 'Free Slot' THEN
      INSERT INTO schedule (title, description, category, subject, start_time, end_time, color)
      VALUES (rec.s4, 'MBA Class - ' || rec.s4, 'MBA Class',
              CASE
                WHEN rec.s4 LIKE 'BSQT%' THEN 'BSQT'
                WHEN rec.s4 LIKE 'FIAC%' THEN 'FIAC'
                WHEN rec.s4 LIKE 'MKMT%' THEN 'MKMT'
                WHEN rec.s4 LIKE 'MAEC%' THEN 'MAEC'
                WHEN rec.s4 LIKE 'ORBE%' THEN 'ORBE'
                WHEN rec.s4 LIKE 'IDD%' THEN 'IDD'
                ELSE 'Other'
              END,
              (session_date + TIME '10:00:00') AT TIME ZONE 'UTC',
              (session_date + TIME '11:00:00') AT TIME ZONE 'UTC',
              color_val);
    END IF;
  END LOOP;
END $$;