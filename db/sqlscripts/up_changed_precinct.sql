-- Simplify your life and Make a temp table with the changed info
CREATE TABLE tt_ocvr_updates AS 
SELECT 
	p.id
  , p.ocvr_voter_id
  , o.precinct
  , o.assignment
  , o.r_address
  , r_city
  , r_state
  , left( trim( o.r_zip ), 5 ) AS r_zip5
  , CASE WHEN length( trim( r_zip ) ) > 5 THEN right( trim( o.r_zip ), 4) ELSE NULL END AS r_zip4
  ,CASE WHEN  length( trim( o.m_address ) ) > 0 THEN o.m_address ELSE NULL END AS m_address
  , o.m_city
  , o.m_state
  , left( trim( o.m_zip ), 5 ) AS m_zip5
  , CASE WHEN length( trim( o.m_zip ) ) > 5 THEN right( trim( o.m_zip ), 4) ELSE NULL END AS m_zip4
FROM t_person p 
JOIN t_import_ocvr_tmp o USING(ocvr_voter_id)
WHERE p.id IN (46, 235, 651);

SELECT * FROM tt_ocvr_updates;

SELECT 
    p.id
  , p.precinct
  , p.assignment
  , o.precinct
  , o.assignment
FROM t_person p 
JOIN tt_ocvr_updates o USING(id);

-- UPDATE t_person with OCVR precinct, assignment
SET SQL_SAFE_UPDATES = 0;
START TRANSACTION;
UPDATE t_person p,  tt_ocvr_updates  o
SET p.precinct = o.precinct
	  , p.assignment = o.assignment
WHERE p.id = o.id;

SELECT * FROM t_address a JOIN tt_ocvr_updates o ON a.person_id = o.id;
SELECT * FROM t_import_ocvr_tmp LIMIT 3 ;

-- UPDATE t_address with residential address
UPDATE t_address a,  tt_ocvr_updates o
SET a.address = o.r_address
	  , a.city = o.r_city
      , a.state = o.r_state
      , a.zip5 = o.r_zip5
      , a.zip4 = o.r_zip4
WHERE a.person_id = o.id
-- AND p.id IN (46, 235, 651) -- not necessary as temp table is limited only to records needed update
AND a.type = 'RESI' ;

SELECT
    a.person_id
  , a.address
  , a.city
  , a.state
  , a.zip5
  , a.zip4
  , o.r_address
  , o.r_zip5
  , o.r_zip4
FROM t_address a 
JOIN tt_ocvr_updates o ON a.person_id = o.id
WHERE a.type = 'RESI' ;

-- inspect before commit
-- COMMIT;
-- ROLLBACK;