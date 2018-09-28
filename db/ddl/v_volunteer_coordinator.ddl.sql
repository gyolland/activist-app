CREATE VIEW v_volunteer_coordinator AS
SELECT
    p.vanid
  , concat(ifnull(p.nickname, p.fname), ' ', p.lname) as name
  , pr.pcp
  , pr.nl
  , pr.vol
  , c.comment
  , p.primary_phone AS phone
  , p.primary_email AS email
  , a.residential_address AS address
  , a.residential_zip AS zip
FROM
  t_person p
JOIN
  v_address a ON p.id = a.person_id
LEFT JOIN
  t_comment c on p.id = c.obj_id;