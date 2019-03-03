-- Mark removed PCP t_person_role record with a term_end_date
-- equal to the MCED report date and set the inactive flag = TRUE

-- create temporary table of the IDs to be marked as removed
CREATE TEMPORARY TABLE tt_removed AS
SELECT
		 p.id AS person_id
	FROM t_person p
	JOIN t_person_role r0 ON p.id = r0.person_id
	JOIN v_address a ON p.id = a.person_id
	LEFT JOIN t_import_ocvr_tmp o USING(ocvr_voter_id)
	WHERE p.gender <> 'X'
	  AND r0.role_id = 3
	  AND r0.inactive = FALSE
	  AND o.ocvr_voter_id IS NULL ;

SET SQL_SAFE_UPDATES = 0;

START TRANSACTION;

UPDATE t_person_role r0, tt_removed AS d 
SET r0.term_end_date = '2019-02-20'
  , r0.inactive = TRUE
WHERE r0.person_id = d.person_id 
AND r0.role_id = 3 ; -- PCP

-- Inspect before commit
SELECT r0.* 
FROM t_person_role r0
JOIN tt_removed AS d USING(person_id)
WHERE r0.role_id = 3; -- PCP

-- COMMIT;
-- ROLLBACK;