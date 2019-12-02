SELECT a.*
FROM t_address a, 
	(SELECT
		p.id AS person_id
	  , 'RESI' AS type
	  , TRIM(o.r_address) AS address
      , o.r_address as untrimmed
	  , o.r_city AS city
	  , o.r_state AS state
	  , left(trim(o.r_zip), 5) AS zip5
	  , CASE WHEN length(trim(o.r_zip)) > 5 THEN right(trim(o.r_zip), 4) ELSE NULL END  AS zip4
	FROM t_person p
	JOIN t_import_ocvr_tmp o USING(ocvr_voter_id) 
	WHERE p.ocvr_voter_id IN ('385430', '300077342', '100215079', '11887203', '11603423', '12359997', '100634621', '100129336', '12198229') ) new_a
WHERE a.person_id = new_a.person_id
AND a.type = new_a.type ;
-- AND a.address <> new_a.address;

SET SQL_SAFE_UPDATES = 0;
START TRANSACTION;

UPDATE t_address a, 
	(SELECT
		p.id AS person_id
	  , 'RESI' AS type
	  , TRIM(o.r_address) AS address
	  , o.r_city AS city
	  , o.r_state AS state
	  , left(trim(o.r_zip), 5) AS zip5
	  , CASE WHEN length(trim(o.r_zip)) > 5 THEN right(trim(o.r_zip), 4) ELSE NULL END  AS zip4
	FROM t_person p
	JOIN t_import_ocvr_tmp o USING(ocvr_voter_id) 
	WHERE p.ocvr_voter_id IN ('385430', '300077342', '100215079', '11887203', '11603423', '12359997', '100634621', '100129336', '12198229') ) new_a

SET a.address = new_a.address
     , a.city = new_a.city
     , a.zip5 = new_a.zip5
     , a.zip4 = CASE WHEN new_a.zip4 IS NULL THEN NULL ELSE new_a.zip4 END

WHERE a.person_id = new_a.person_id
AND a.type = new_a.type
AND a.address <> new_a.address;

COMMIT;

SELECT *
FROM
    (SELECT
		p.id AS person_id
	  , 'RESI' AS type
	  , TRIM(o.r_address) AS address
      , a0.address as old_address
      , a.address AS m_address
	  , o.r_city AS city
	  , o.r_state AS state
	  , left(trim(o.r_zip), 5) AS zip5
	  , CASE WHEN length(trim(o.r_zip)) > 5 THEN right(trim(o.r_zip), 4) ELSE NULL END  AS zip4
	FROM t_person p
	JOIN t_import_ocvr_tmp o USING(ocvr_voter_id)
    JOIN ( SELECT * FROM t_address WHERE type = 'RESI'  ) a0 ON p.id = a0.person_id 
    LEFT JOIN ( SELECT * FROM t_address WHERE type = 'MAIL'  ) a ON p.id = a.person_id ) new_a
    WHERE m_address IS NOT NULL 
    AND address <> m_address ;

SET SQL_SAFE_UPDATES = 0;
START TRANSACTION;

UPDATE t_address a, 
	(SELECT
		p.id AS person_id
	  , 'RESI' AS type
	  , TRIM(o.r_address) AS address
      , o.r_address as untrimmed
	  , o.r_city AS city
	  , o.r_state AS state
	  , left(trim(o.r_zip), 5) AS zip5
	  , CASE WHEN length(trim(o.r_zip)) > 5 THEN right(trim(o.r_zip), 4) ELSE NULL END  AS zip4
	FROM t_person p
	JOIN t_import_ocvr_tmp o USING(ocvr_voter_id)  ) new_a
    
    SET a.address = new_a.address
     , a.city = new_a.city
     , a.zip5 = new_a.zip5
     , a.zip4 = CASE WHEN new_a.zip4 IS NULL THEN NULL ELSE new_a.zip4 END

WHERE a.person_id = new_a.person_id
AND a.type = new_a.type
AND a.address <> new_a.address;

commit;