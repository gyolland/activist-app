-- UPDATE t_person_stage with VAN data
SET SQL_SAFE_UPDATES = 0;
START TRANSACTION;
UPDATE t_person_stage ps, t_import_pcp_van_tmp v
SET ps.vanprecinct = trim(v.vanprecinct)
    , ps.cd = CASE WHEN v.cd <> 0 THEN v.cd ELSE NULL END
    , ps.vanid = v.vanid
WHERE ps.precinct = mcedprecinct AND ps.lname = v.lname ;
-- inspect before commit
-- COMMIT;
-- ROLLBACK;