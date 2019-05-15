-- identify the PCP that had been a PCP in the past but is now becoming a PCP again
-- The likely cause is that the PCP has moved precincts and needed to be reappointed 
-- after becoming ineligible as a result of the move.
SELECT 
    p.id
  , p.precinct
  , p.cd
  , o.ocvr_voter_id
  , p.vanid
  , p.fname
  , p.lname
  , p.middlename
  , p.nickname
  , p.gender
  , '' AS fname_change
  , '' AS lname_change
  , CASE WHEN (p.precinct <> o.precinct) = 0 THEN null ELSE CONCAT('OCVR: ', o.precinct) END AS precinct_change
  -- , p.assignment
  , f_get_assignment_date(p.assignment) AS old_assignment_date
  -- , o.assignment AS oassignment
  , f_get_assignment_date(o.assignment) AS new_assignment_date
  -- , r0.*
FROM t_person p 
JOIN t_import_ocvr_tmp o USING(ocvr_voter_id)
JOIN t_person_role r0 ON p.id = r0.person_id
WHERE role_id = 3 -- PCP
AND r0.term_end_date < now()
AND r0.term_end_date IS NOT NULL 
-- AND f_get_assignment_date(p.assignment) < f_get_assignment_date(o.assignment)
ORDER BY r0.person_id, r0.term_end_date ;

-- SELECT PCPs newly appointed with previous Elected/Appointment that has expired term_end_date
SELECT
    p.id
  , p.precinct
  , p.cd
  , p.ocvr_voter_id
  , p.vanid
  , p.fname
  , p.lname
  , p.middlename
  , p.nickname
  , p.gender
  , f_get_assignment_date(p.assignment) AS old_assignment_date
  , f_get_assignment_date(o.assignment) AS new_assignment_date
--   , CASE WHEN p.fname <> f_get_word_part(o.fname, 1) 
--        THEN concat('OCVR: ',  f_get_word_part(o.fname, 1)) END AS fname_change
--   , CASE WHEN p.lname <> replace( trim(o.lname), ' ', '' )
--        THEN concat('OCVR: ',  trim(o.lname)) END AS lname_change
 ,  CASE WHEN p.precinct <> o.precinct 
       THEN concat('OCVR: ', o.precinct) END AS precinct_change
FROM t_person p 
JOIN t_import_ocvr_tmp o USING(ocvr_voter_id)
JOIN
	(SELECT
		p.id
	  , p.ocvr_voter_id
	  , MAX(r0.term_end_date) AS term_end_date
	FROM t_person p
	JOIN t_person_role r0 ON p.id = r0.person_id
	JOIN t_import_ocvr_tmp o USING(ocvr_voter_id)
	WHERE r0.role_id = 3 -- PCPs
	GROUP BY p.id, p.ocvr_voter_id
	HAVING MAX(r0.term_end_date) < NOW()) b  USING(id) ;
