-- UPDATE primary_phone & primary_email from PCP Applicant Form.
SET SQL_SAFE_UPDATES = 0;
START TRANSACTION;
UPDATE t_person_stage ps, t_import_pcp_applicant_form f 
SET ps.primary_phone = trim(replace(f.phone, '-', ''))
      , ps.primary_email = trim(f.email)
WHERE ps.precinct = f.precinct AND ps.lname = f.lname ;

-- inspect before commit
-- COMMIT;
-- ROLLBACK;

SELECT * FROM t_person_stage ;

SELECT * FROM t_import_pcp_applicant_form ;