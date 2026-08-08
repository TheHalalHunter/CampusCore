-- =============================================================================
-- CampusCore Seed Data
-- Phase 1: Fisheries & Aquaculture, LAUTECH
--
-- All courses are open to ALL students in the department regardless of level.
-- A 500L student can browse and download 100L past questions and notes.
-- Resources are attached to courses — not to students or cohorts.
-- =============================================================================

DO $$
DECLARE dept_id UUID;
BEGIN
  SELECT id INTO dept_id FROM departments
  WHERE name = 'Fisheries & Aquaculture' LIMIT 1;

  -- 100L Semester 1
  INSERT INTO courses (title, course_code, department_id, credit_units, academic_level, semester) VALUES
    ('Introduction to Fisheries and Aquaculture', 'AQU 101', dept_id, 2, '100L', 1),
    ('General Biology I',                          'BIO 101', dept_id, 3, '100L', 1),
    ('General Chemistry I',                        'CHM 101', dept_id, 3, '100L', 1),
    ('Use of English I',                           'GST 101', dept_id, 2, '100L', 1),
    ('Introduction to Computer Science',           'CSC 101', dept_id, 2, '100L', 1),
    ('Mathematics for Biological Sciences I',      'MTH 101', dept_id, 3, '100L', 1);

  -- 100L Semester 2
  INSERT INTO courses (title, course_code, department_id, credit_units, academic_level, semester) VALUES
    ('Introduction to Aquatic Biology',            'AQU 102', dept_id, 2, '100L', 2),
    ('General Biology II',                         'BIO 102', dept_id, 3, '100L', 2),
    ('General Chemistry II',                       'CHM 102', dept_id, 3, '100L', 2),
    ('Use of English II',                          'GST 102', dept_id, 2, '100L', 2),
    ('Mathematics for Biological Sciences II',     'MTH 102', dept_id, 3, '100L', 2);

  -- 200L Semester 1
  INSERT INTO courses (title, course_code, department_id, credit_units, academic_level, semester) VALUES
    ('Fish Nutrition and Feeding',                 'AQU 201', dept_id, 2, '200L', 1),
    ('Aquatic Ecology',                            'AQU 203', dept_id, 3, '200L', 1),
    ('Fish Anatomy and Physiology',                'AQU 205', dept_id, 3, '200L', 1),
    ('Principles of Genetics',                     'BIO 207', dept_id, 2, '200L', 1),
    ('Biostatistics',                              'STA 201', dept_id, 2, '200L', 1),
    ('Soil Science for Aquaculture',               'AQU 207', dept_id, 2, '200L', 1);

  -- 200L Semester 2
  INSERT INTO courses (title, course_code, department_id, credit_units, academic_level, semester) VALUES
    ('Fish Parasitology and Diseases',             'AQU 202', dept_id, 3, '200L', 2),
    ('Pond Management and Construction',           'AQU 204', dept_id, 2, '200L', 2),
    ('Aquaculture Technology',                     'AQU 206', dept_id, 3, '200L', 2),
    ('Water Quality Management',                   'AQU 208', dept_id, 2, '200L', 2),
    ('Microbiology for Aquaculture',               'BIO 204', dept_id, 2, '200L', 2);

  -- 300L Semester 1
  INSERT INTO courses (title, course_code, department_id, credit_units, academic_level, semester) VALUES
    ('Fish Processing and Preservation',           'AQU 301', dept_id, 3, '300L', 1),
    ('Genetics and Fish Breeding',                 'AQU 303', dept_id, 3, '300L', 1),
    ('Fisheries Management',                       'AQU 305', dept_id, 2, '300L', 1),
    ('Aquatic Toxicology',                         'AQU 307', dept_id, 2, '300L', 1),
    ('Research Methods in Fisheries',              'AQU 309', dept_id, 2, '300L', 1),
    ('Limnology',                                  'AQU 311', dept_id, 2, '300L', 1);

  -- 300L Semester 2
  INSERT INTO courses (title, course_code, department_id, credit_units, academic_level, semester) VALUES
    ('Crustacean and Molluscan Culture',           'AQU 302', dept_id, 3, '300L', 2),
    ('Fish Marketing and Economics',               'AQU 304', dept_id, 2, '300L', 2),
    ('Environmental Impact Assessment',            'AQU 306', dept_id, 2, '300L', 2),
    ('Ornamental Fish Culture',                    'AQU 308', dept_id, 2, '300L', 2),
    ('Industrial Training (SIWES)',                'AQU 310', dept_id, 6, '300L', 2);

  -- 400L Semester 1
  INSERT INTO courses (title, course_code, department_id, credit_units, academic_level, semester) VALUES
    ('Advanced Aquaculture Systems',               'AQU 401', dept_id, 3, '400L', 1),
    ('Fisheries Law and Policy',                   'AQU 403', dept_id, 2, '400L', 1),
    ('Fish Feed Formulation and Technology',       'AQU 405', dept_id, 3, '400L', 1),
    ('Marine Fisheries',                           'AQU 407', dept_id, 2, '400L', 1),
    ('Project Research I',                         'AQU 409', dept_id, 3, '400L', 1),
    ('Aquatic Pollution and Control',              'AQU 411', dept_id, 2, '400L', 1);

  -- 400L Semester 2
  INSERT INTO courses (title, course_code, department_id, credit_units, academic_level, semester) VALUES
    ('Recirculatory Aquaculture Systems',          'AQU 402', dept_id, 3, '400L', 2),
    ('Fisheries Extension and Development',        'AQU 404', dept_id, 2, '400L', 2),
    ('Post-Harvest Technology',                    'AQU 406', dept_id, 2, '400L', 2),
    ('Entrepreneurship in Aquaculture',            'AQU 408', dept_id, 2, '400L', 2),
    ('Industrial Training (SIWES) II',             'AQU 410', dept_id, 6, '400L', 2);

  -- 500L Semester 1
  INSERT INTO courses (title, course_code, department_id, credit_units, academic_level, semester) VALUES
    ('Advanced Fish Genetics and Biotechnology',   'AQU 501', dept_id, 3, '500L', 1),
    ('Integrated Aquaculture Systems',             'AQU 503', dept_id, 3, '500L', 1),
    ('Fisheries Economics and Management',         'AQU 505', dept_id, 2, '500L', 1),
    ('Climate Change and Aquatic Resources',       'AQU 507', dept_id, 2, '500L', 1),
    ('Final Year Project I',                       'AQU 509', dept_id, 4, '500L', 1),
    ('Fisheries Policy and International Law',     'AQU 511', dept_id, 2, '500L', 1);

  -- 500L Semester 2
  INSERT INTO courses (title, course_code, department_id, credit_units, academic_level, semester) VALUES
    ('Aquaculture Business Development',           'AQU 502', dept_id, 2, '500L', 2),
    ('Marine and Inland Capture Fisheries',        'AQU 504', dept_id, 3, '500L', 2),
    ('Fish Immunology and Vaccinology',            'AQU 506', dept_id, 2, '500L', 2),
    ('Professional Ethics in Fisheries',           'AQU 508', dept_id, 2, '500L', 2),
    ('Final Year Project II',                      'AQU 510', dept_id, 6, '500L', 2);

END $$;
