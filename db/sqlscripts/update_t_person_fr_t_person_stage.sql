-- Update t_person from t_person_stage
SET SQL_SAFE_UPDATES = 0;
START TRANSACTION;

UPDATE t_person p, t_person_stage ps
SET p.vanprecinct = ps.vanprecinct
	  , p.cd = ps.cd
      , p.vanid = ps.vanid
      , p.primary_phone = ps.primary_phone
      , p.primary_email = ps.primary_email
WHERE p.id = ps.id ;

-- inspect before commit
-- COMMIT;
-- ROLLBACK;