-- Insert into t_person_role with assignment data from OCVR data
SET SQL_SAFE_UPDATES = 0;
START TRANSACTION;

INSERT INTO t_person_role
   (person_id, role_id, certified_pcp, elected, term_start_date, term_end_date, inactive)
SELECT 
    p.id AS person_id
  , 3 AS role_id
  , true AS certified_pcp
  , false AS elected
  , f_get_assignment_date(o.assignment) AS term_start_date
  , (SELECT MAX(term_end_date) FROM t_person_role) AS term_end_date
  , FALSE AS inactive
FROM t_person p 
JOIN t_import_ocvr_tmp o USING(ocvr_voter_id)
WHERE p.ocvr_voter_id = '300077342' ;

COMMIT;
