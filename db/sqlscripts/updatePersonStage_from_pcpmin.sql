-- update t_person_stage with data collected from van
SET SQL_SAFE_UPDATES = 0;
START TRANSACTION;

UPDATE t_person_stage ps, t_import_pcp_van_min_tmp v 
SET ps.vanid = v.vanid
      , ps.cd = v.cd
      , ps.vanprecinct = v.vanprecinct
WHERE ps.ocvr_voter_id = v.ocvr_voter_id ;

SELECT * FROM t_person_stage ;

-- insect before commit
COMMIT ;
-- ROLLBACK;