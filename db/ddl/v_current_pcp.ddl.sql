-CREATE VIEW `v_current_pcp` AS
SELECT
    p.vanid AS VANID
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
  , p.primary_phone AS 'Home Phone'
  , '' AS 'Cell Phone'
  , am.address AS 'MailingAddress'
  , am.city AS 'MailingCity'
  , am.state AS 'MailingState'
  , CASE WHEN am.zip4 IS NULL
	THEN am.zip5
    ELSE concat(am.zip5, '-', am.zip4)
    END AS 'MailingZip'
  , replace(c.comment, 'assignment: ', '') AS 'ASSIGNMENT'
FROM t_person p 
JOIN t_person_role pr ON p.id = pr.person_id
JOIN (SELECT * FROM t_address WHERE type = 'RESI') ar ON p.id = ar.person_id
LEFT JOIN (SELECT * FROM t_address WHERE type = 'MAIL') am ON p.id = am.person_id
LEFT JOIN (SELECT obj_id, comment FROM t_comment WHERE comment LIKE '%assignment:%') c ON p.id = c.obj_id
WHERE pr.role_id = 3
AND pr.term_start_date < now()
AND pr.term_end_date > now();