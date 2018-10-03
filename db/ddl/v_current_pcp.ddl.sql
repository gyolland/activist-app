CREATE OR REPLACE VIEW `v_current_pcp` AS
SELECT
    p.vanid AS VANID
  , p.vanprecinct AS VANPrecinct
  , p.precinct AS 'MCEDPrecinct'
  , p.cd AS 'CD'
  , p.lname AS 'LastName'
  , p.fname AS 'FirstName'
  , p.middlename AS 'MiddleName'
  , p.nickname AS 'NickName'
  , NULL AS 'Suffix'
  , p.gender AS 'Sex'
  , ar.address AS 'Address'
  , ar.city AS 'City'
  , ar.state AS 'State/Province'
  , ar.zip5 AS 'Zip/Postal'
  , ar.zip4 AS 'Zip4'
  , 'US' AS 'CountryCode'
  , p.primary_email AS 'PreferredEmail'
  , p.primary_phone AS 'Home/Phone 1'
  , p.allow_text1 AS 'Phone 1 Allow Text'
  , p.phone2 AS 'Cell/Phone 2'
  , p.allow_text2 AS 'Phone 2 Allow Text'
  , am.address AS 'MailingAddress'
  , am.city AS 'MailingCity'
  , am.state AS 'MailingState'
  , CASE WHEN am.zip4 IS NULL
	  THEN am.zip5
    ELSE concat(am.zip5, '-', am.zip4)
    END AS 'MailingZip'
  , CASE WHEN r0.elected = TRUE THEN 'Elected' ELSE 'Appointed' END AS 'Elected or Appointed'
  , CASE WHEN p.nda_on_file = TRUE THEN 'Yes' ELSE 'No' END AS 'NDA on File'
  , p.assignment AS 'ASSIGNMENT'
FROM t_person p 
JOIN t_person_role r0 ON p.id = r0.person_id
JOIN (SELECT * FROM t_address WHERE type = 'RESI') ar ON p.id = ar.person_id
LEFT JOIN (SELECT * FROM t_address WHERE type = 'MAIL') am ON p.id = am.person_id
LEFT JOIN t_comment c ON p.id = c.obj_id
WHERE r0.role_id = 3
AND r0.term_start_date < now()
AND r0.term_end_date > now();