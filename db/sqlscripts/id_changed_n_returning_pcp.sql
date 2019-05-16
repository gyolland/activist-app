-- Union query to select both the PCPs that have changed precinct or address
-- and those returning as a PCP after having become ineligible.
-- Decided not take on name changes in this section as names will likely
-- require some human intervention.
SELECT id, precinct_change, address_change, returning_pcp
FROM (
	SELECT
			p.id
		, CASE WHEN p.fname <> f_get_word_part(o.fname, 1) 
			THEN 'X' ELSE '' END AS fname_change
		, CASE
		  WHEN p.lname <> trim(o.lname)
		   AND p.lname <> replace( trim(o.lname), ' ', '' )
		   AND replace(p.lname, '-', ' ') <> trim(o.lname)
		  THEN 'X' ELSE '' END AS lname_change
		, CASE WHEN p.precinct <> o.precinct 
			THEN 'X' ELSE '' END AS precinct_change
		, CASE WHEN a.address <> o.r_address 
			THEN 'X' ELSE '' END AS address_change
		, '' AS returning_pcp
		FROM t_person p 
		JOIN t_person_role r0 ON p.id = r0.person_id
		JOIN t_import_ocvr_tmp o USING(ocvr_voter_id)
		JOIN t_address a ON p.id = a.person_id
		WHERE r0.role_id = 3 
		AND r0.inactive = FALSE
		AND a.type = 'RESI' 
		UNION ALL
		SELECT * FROM
		(SELECT
			p.id
		, CASE WHEN p.fname <> f_get_word_part(o.fname, 1) 
			THEN 'X' ELSE '' END AS fname_change
		, CASE
		  WHEN p.lname <> trim(o.lname)
		   AND p.lname <> replace( trim(o.lname), ' ', '' )
		   AND replace(p.lname, '-', ' ') <> trim(o.lname)
		  THEN 'X' ELSE '' END AS lname_change
		, CASE WHEN p.precinct <> o.precinct 
			THEN 'X' ELSE '' END AS precinct_change
		, CASE WHEN a.address <> o.r_address 
			THEN 'X' ELSE '' END AS address_change
		, 'X' AS returning_pcp
		FROM t_person p 
	JOIN t_import_ocvr_tmp o USING(ocvr_voter_id)
	JOIN t_person_role r0 ON p.id = r0.person_id
	JOIN (SELECT * FROM t_address WHERE type = 'RESI') a ON p.id = a.person_id
	WHERE role_id = 3 -- PCP
	AND r0.term_end_date < now()
	AND r0.inactive = TRUE
	ORDER BY r0.person_id, r0.term_end_date) xxx ) zzz
WHERE ( precinct_change = 'X'
OR address_change = 'X' 
OR returning_pcp = 'X' ) 
ORDER BY id ;



