-- update t_person_stage with data collected from van
SET SQL_SAFE_UPDATES = 0;
START TRANSACTION;

-- UPDATE t_person_stage ps, t_import_pcp_van_min_tmp v 
-- SET ps.vanid = v.vanid
--       , ps.cd = v.cd
--       , ps.vanprecinct = v.vanprecinct
-- WHERE ps.ocvr_voter_id = v.ocvr_voter_id ;

-- ocvr_voter_id/external id seems to no longer be exportable in VAN
-- manually update vanid in t_person_stage
UPDATE t_person_stage ps, t_import_pcp_van_min_tmp v 
SET ps.cd = v.cd
      , ps.vanprecinct = v.vanprecinct
      , ps.primary_phone = v.preferred_phone
      , ps.primary_email = v.preferred_email
WHERE ps.vanid = v.vanid ;

SELECT * FROM t_person_stage ;

-- insect before commit
COMMIT ;
-- ROLLBACK;

-- Alternate: Assumes mapping in OCVR_VOTER_ID
-- NOTE: NOT USENG t_person_stage
UPDATE t_person p, t_import_pcp_van_min_tmp v 
SET p.vanid = ifnull(p.vanid, v.vanid)
      , p.vanprecinct = v.vanprecinct
      , p.cd = ifnull(p.cd, v.cd)
      , p.primary_phone = ifnull(p.primary_phone, v.preferred_phone)
      , p.primary_email = ifnull(p.primary_email, v.preferred_email)
WHERE p.ocvr_voter_id = v.ocvr_voter_id ;