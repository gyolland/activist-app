-- 
-- SET SQL_SAFE_UPDATES = 0;
START TRANSACTION;

INSERT INTO t_address(person_id, type, address, city, state, zip5, zip4) 
SELECT
    ps.id AS person_id
  , 'RESI' AS type
  , o.r_address AS address
  , o.r_city AS city
  , o.r_state AS state
  , left(trim(o.r_zip), 5) AS zip5
  , CASE WHEN length(trim(o.r_zip)) > 5 THEN right(trim(o.r_zip), 4) ELSE NULL END  AS zip4
FROM t_person_stage ps 
JOIN t_import_ocvr_tmp o USING(ocvr_voter_id) 
UNION ALL
SELECT
    ps.id AS person_id
  , 'MAIL' AS type
  , o.m_address AS address
  , o.m_city AS city
  , o.m_state AS state
  , left(trim(o.m_zip), 5) AS zip5
  , CASE WHEN length(trim(o.m_zip)) > 5 THEN right(trim(o.m_zip), 4) ELSE NULL END AS zip4
FROM t_person_stage ps 
JOIN t_import_ocvr_tmp o USING(ocvr_voter_id) 
WHERE length(trim(o.m_address)) > 0 ;

-- inspect before commit
SELECT a.* 
FROM v_address a 
JOIN t_person_stage ps ON a.person_id = ps.id ;

-- COMMIT;
-- ROLLBACK;