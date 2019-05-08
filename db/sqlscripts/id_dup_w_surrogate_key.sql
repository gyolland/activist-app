-- develop away to id existing PCPs using a surrogate key composed of 
-- last name, first name, middle name, gender, & address
-- against t_import_ocvr_tmp 
SELECT
	o.ocvr_voter_id
  , o.fname
  , o.middlename
  , o.lname
  , o.gender
  , o.address
  , UCASE(CONCAT(o.lname
			   , substr(o.fname, 1, 2)
               ,  ifnull(substr(o.middlename, 1, 1) , '') 
			   , o.gender
			   , trim(substr(o.address, 1, instr(o.address, ' '))))) AS surrogate_key
FROM
	(SELECT 
		o.ocvr_voter_id
	  , o.lname
	  , f_get_word_part(o.fname, 1) AS fname
	   , f_get_word_part(o.fname, 2) AS middlename
	  , substr(o.gender, 1, 1) AS gender
	  , o.r_address AS address
	FROM t_import_ocvr_tmp o) AS o
    LIMIT 10 ;

-- also can be used to identify duplicates in existing records
-- against t_person and t_address
SELECT surrogate_key, count(*) recs
FROM
	(SELECT
		o.ocvr_voter_id
	  , o.fname
	  , o.middlename
	  , o.lname
	  , o.gender
	  , o.address
	  , UCASE(CONCAT(o.lname
				   , substr(o.fname, 1, 2)
				   ,  ifnull(substr(o.middlename, 1, 1) , '') 
				   , o.gender
				   , trim(substr(o.address, 1, instr(o.address, ' '))))) AS surrogate_key
	FROM
		(SELECT 
			p0.ocvr_voter_id
		  , p0.lname
		  , p0.fname
		  , p0.middlename
		  , p0.gender
		  , a0.address AS address
		FROM t_person p0
		JOIN (SELECT * FROM t_address WHERE type = 'RESI' ) AS a0 ON p0.id = a0.person_id) AS o) sk
GROUP BY surrogate_key
HAVING count(*) > 1;