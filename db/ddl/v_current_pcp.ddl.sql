CREATE OR REPLACE VIEW v_current_pcp AS
SELECT
    p.vanid
  , p.vanprecinct
  , p.precinct AS mcedprecinct
  , p.cd 
  , p.lname AS LastName
  , p.fname AS FirstName
  , p.middlename AS MiddleName
  , p.nickname AS NickName
  , p.suffix
  , p.gender AS Gender
  , ar.address
  , ar.city
  , ar.state
  , ar.zip5
  , ar.zip4
  , 'US' AS countrycode
  , p.primary_email AS preferredemail
  , p.primary_phone AS home_phone1
  , CASE WHEN p.allow_text1 = TRUE THEN 'Yes' ELSE 'No' END AS phone1_allow_text
  , p.phone2 AS cell_phone2
  , CASE WHEN p.allow_text2 = TRUE THEN 'Yes' ELSE 'No' END AS phone2_allow_text
  , am.address AS mailingaddress
  , am.city AS mailingcity
  , am.state AS mailingstate
  , CASE WHEN am.zip4 IS NULL
	  THEN am.zip5
    ELSE concat(am.zip5, '-', am.zip4)
    END AS mailingzip
  , CASE WHEN r0.elected = TRUE THEN 'Elected' ELSE 'Appointed' END AS elected_or_appointed
  , CASE WHEN p.nda_on_file = TRUE THEN 'Yes' ELSE 'No' END AS nda_on_file
  , p.assignment
FROM t_person p 
JOIN t_person_role r0 ON p.id = r0.person_id
JOIN (SELECT * FROM t_address WHERE type = 'RESI') ar ON p.id = ar.person_id
LEFT JOIN (SELECT * FROM t_address WHERE type = 'MAIL') am ON p.id = am.person_id
LEFT JOIN t_comment c ON p.id = c.obj_id
WHERE r0.role_id = 3
AND r0.term_start_date < now()
AND r0.term_end_date > now();