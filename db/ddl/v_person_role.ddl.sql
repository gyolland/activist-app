CREATE OR REPLACE VIEW v_person_role AS
    SELECT 
        x.id AS id,
        x.precinct AS precinct,
        x.ocvr_voter_id AS ocvr_voter_id,
        x.vanid AS vanid,
        x.fname AS fname,
        x.lname AS lname,
        x.middlename AS middlename,
        x.nickname AS nickname,
        x.gender AS gender,
        x.primary_phone AS primary_phone,
        x.primary_email AS primary_email,
        (CASE x.PCP
            WHEN 1 THEN 'P'
            ELSE ''
        END) AS PCP,
        (CASE x.NL
            WHEN 1 THEN 'N'
            ELSE ''
        END) AS NL,
        (CASE x.VOL
            WHEN 1 THEN 'V'
            ELSE ''
        END) AS VOL,
        (CASE x.DL
            WHEN 1 THEN 'L'
            ELSE ''
        END) AS DL
    FROM
        (SELECT 
            p.id AS id,
                p.precinct AS precinct,
                p.ocvr_voter_id AS ocvr_voter_id,
                p.vanid AS vanid,
                p.fname AS fname,
                p.lname AS lname,
                p.middlename AS middlename,
                p.nickname AS nickname,
                p.gender AS gender,
                p.primary_phone AS primary_phone,
                p.primary_email AS primary_email,
                COUNT((CASE pr.role_id
                    WHEN 3 THEN 'P'
                    ELSE NULL
                END)) AS PCP,
                COUNT((CASE pr.role_id
                    WHEN 16 THEN 'N'
                    ELSE NULL
                END)) AS NL,
                COUNT((CASE pr.role_id
                    WHEN 18 THEN 'V'
                    ELSE NULL
                END)) AS VOL,
                COUNT((CASE pr.role_id
                    WHEN 13 THEN 'L'
                    ELSE NULL
                END)) AS DL
        FROM
            ((t_person p
        LEFT JOIN t_person_role pr ON ((p.id = pr.person_id)))
        JOIN t_role r ON ((pr.role_id = r.id)))
        GROUP BY p.id , p.precinct , p.ocvr_voter_id , p.vanid , p.fname , p.lname , p.middlename , p.nickname , p.gender , p.primary_phone , p.primary_email) x