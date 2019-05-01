-- identify potential duplicate PCPs by creating a surrogate key based on the
-- concatenation of Last name, first 2 characters of the first name, first character
-- of the middlename, gender, and address number
SELECT surrogate_key, count(*) recs
FROM (
	SELECT
		p.id
	  , p.lname
	  , p.fname
      , ifnull(substr(p.middlename, 1, 1) , '')  AS mi 
	  , p.gender
	  , p.ocvr_voter_id
	  , a.address
	  , UCASE(CONCAT(p.lname
			   , substr(p.fname, 1, 2)
               ,  ifnull(substr(p.middlename, 1, 1) , '') 
			   , gender
			   , trim(substr(a.address, 1, instr(a.address, ' '))))) AS surrogate_key
	FROM t_person p
	JOIN t_person_role r0 ON p.id = r0.person_id
	JOIN t_address a ON p.id = a.person_id
	WHERE r0.role_id = 3
	AND r0.inactive = false
	AND a.type = 'RESI' ) k
GROUP BY surrogate_key
HAVING count(*) > 1 ;
