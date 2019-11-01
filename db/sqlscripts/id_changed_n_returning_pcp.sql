-- Union query to select both the PCPs that have changed precinct or address
-- and those returning as a PCP after having become ineligible.
-- Decided not take on name changes in this section as names will likely
-- require some human intervention.
SELECT *
FROM 
    (SELECT
          p.id
        , concat(p.fname, ' ', p.lname) name
        , p.gender
        , CASE 
            WHEN p.precinct <> o.precinct 
            THEN 'X' ELSE '' END AS precinct_change
        , CASE 
            WHEN a.address <> o.r_address 
            THEN 'X' ELSE '' END AS address_change
        , '' AS returning_pcp
        , '' AS removed
       FROM t_person p 
       JOIN t_person_role r0 ON p.id = r0.person_id
       JOIN t_import_ocvr_tmp o USING(ocvr_voter_id)
       JOIN t_address a ON p.id = a.person_id
      WHERE  r0.role_id = 3 
        AND r0.inactive = FALSE
        AND a.type = 'RESI' 
UNION ALL
	SELECT
			  p.id
			, concat(p.fname, ' ', p.lname) name
			, p.gender
			, ''   AS precinct_change
			, ''   AS address_change
			, ''   AS returning_pcp
			, 'X' AS removed
		   FROM t_person p 
		   JOIN t_person_role r0 ON p.id = r0.person_id
		   LEFT JOIN t_import_ocvr_tmp o USING(ocvr_voter_id)
		   WHERE p.gender <> 'X'
	  AND r0.role_id = 3
	  AND r0.inactive = FALSE
	  AND o.ocvr_voter_id IS NULL
UNION ALL
    SELECT
        pers.id
        , concat(pers.fname, ' ', pers.lname) name
        , pers.gender
        , CASE 
            WHEN pers.precinct <> ocvr.precinct 
            THEN 'X' ELSE '' END AS precinct_change
        , CASE 
            WHEN a.address <> ocvr.r_address 
            THEN 'X' ELSE '' END AS address_change
        , 'X' AS returning_pcp
        , ''    AS removed
    FROM t_person pers 
    JOIN t_import_ocvr_tmp ocvr USING (ocvr_voter_id)
    JOIN t_address a ON pers.id = a.person_id
    JOIN ( SELECT * 
				   FROM t_person_role
				WHERE inactive = TRUE 
                      AND role_id = 3 
                      AND term_end_date < now() ) r00 ON pers.id = r00.person_id
    WHERE  NOT EXISTS (SELECT 'X' 
											   FROM t_person_role t0 
											WHERE pers.id = t0.person_id 
												  AND t0.inactive = FALSE 
												  AND t0.role_id = 3)  ) u 
WHERE (
          precinct_change 	= 'X'
    OR address_change 	= 'X' 
    OR returning_pcp 		= 'X'
    OR removed 				= 'X' ) 
ORDER BY id ;