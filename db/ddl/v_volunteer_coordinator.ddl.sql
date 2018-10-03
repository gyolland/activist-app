CREATE OR REPLACE VIEW v_volunteer_coordinator AS
SELECT 
    p.vanid AS vanid,
    CONCAT(IFNULL(p.nickname, p.fname), ' ', p.lname) AS name,
    r0.PCP AS pcp,
    r0.NL AS nl,
    r0.VOL AS vol,
    c.comment AS comment,
    p.primary_phone AS phone,
    p.primary_email AS email,
    a.residential_address AS address,
    a.residential_zip AS zip
FROM
    t_person p
    JOIN v_address a ON p.id = a.person_id
    JOIN v_person_role r0 ON p.id = r0.id
    LEFT JOIN t_comment c ON p.id = c.obj_id
ORDER BY CONCAT(IFNULL(p.nickname, p.fname), ' ', p.lname) ;