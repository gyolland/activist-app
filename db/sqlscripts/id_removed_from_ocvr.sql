--  * PCPs no longer in OCVR data, 
-- select from t_person where role is PCP but no longer in OCVR data
-- to prevent person identifying as non-binary gender appearing in this selection,
-- gender <> 'X' is specified in the query. 
SELECT
    vanid
  ,  p.id AS person_id
  ,  p.precinct
  ,  p.ocvr_voter_id
--  ,  o.fname AS ofname
  ,  p.fname
  ,  p.middlename
  ,  p.lname
  -- ,  p.gender
  ,  a.residential_address AS r_address
  ,  a.residential_zip AS r_zip
  ,  p.assignment
  , 'REMOVED' AS status
FROM t_person p
JOIN t_person_role r0 ON p.id = r0.person_id
JOIN v_address a ON p.id = a.person_id
LEFT JOIN t_import_ocvr_tmp o USING(ocvr_voter_id)
WHERE r0.role_id = 3
  AND r0.inactive = FALSE
  AND o.ocvr_voter_id IS NULL;
