SELECT
    p.id
  , p.precinct
  , p.cd
  , p.ocvr_voter_id
  , p.vanid
  , p.fname
  , p.lname
  , p.middlename
  , p.gender
  , CASE WHEN p.fname <> f_get_word_part(o.fname, 1) 
       THEN 'X' ELSE '' END AS fname_change
  , CASE WHEN p.lname <> replace( trim(o.lname), ' ', '' )
       THEN 'X' ELSE '' END AS lname_change
 , CASE WHEN p.precinct <> o.precinct 
       THEN 'X' ELSE '' END AS precinct_change
 , CASE WHEN a.address <> o.r_address 
       THEN 'X' ELSE '' END AS address_change
FROM t_person p 
JOIN t_person_role r0 ON p.id = r0.person_id
JOIN t_import_ocvr_tmp o USING(ocvr_voter_id)
JOIN t_address a ON p.id = a.person_id
WHERE r0.role_id = 3 
  AND r0.inactive = FALSE
  AND a.type = 'RESI'
  AND (p.fname <>  f_get_word_part(o.fname, 1) 
    OR p.lname <> trim(o.lname)
    OR p.precinct <> o.precinct
    OR a.address <> o.r_address) 
