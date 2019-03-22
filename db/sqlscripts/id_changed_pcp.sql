--  * changed PCPs: at least different precinct (maybe more)
-- identify changed PCPs in t_person as compared to new OCVR data
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
  , CASE WHEN p.fname <> f_get_word_part(o.fname, 1) 
       THEN concat('OCVR: ',  f_get_word_part(o.fname, 1)) END AS fname_change
  , CASE WHEN p.lname <> replace( trim(o.lname), ' ', '' )
       THEN concat('OCVR: ',  trim(o.lname)) END AS lname_change
 , CASE WHEN p.precinct <> o.precinct 
       THEN concat('OCVR: ', o.precinct) END AS precinct_change
FROM t_person p 
JOIN t_person_role r0 ON p.id = r0.person_id
JOIN t_import_ocvr_tmp o USING(ocvr_voter_id)
WHERE r0.role_id = 3 -- PCP
	AND r0.inactive = FALSE
	AND (p.fname <>  f_get_word_part(o.fname, 1) 
	  OR p.lname <> trim(o.lname)
	  OR p.precinct <> o.precinct) ;
