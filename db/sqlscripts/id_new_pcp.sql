--  * new PCPs, 
-- select new ocvr entries, missing from t_person
SELECT
     'NEW' AS status
  ,  p.id AS person_id
  ,  o.precinct
  ,  o.ocvr_voter_id
--  ,  o.fname AS ofname
--  ,  f_parse_firstname(o.fname) as fname
  ,  f_get_word_part(o.fname, 1) AS fname
  ,  CASE instr(trim(o.fname), ' ') WHEN 0 THEN NULL
     ELSE trim(substr(trim(o.fname), instr(trim(o.fname), ' '), 100))
     END middlename
  ,  o.lname
  ,  o.gender
  ,  o.r_address
  ,  o.r_zip
FROM t_person p
RIGHT JOIN t_import_ocvr_tmp o USING(ocvr_voter_id)
WHERE p.id IS NULL;
