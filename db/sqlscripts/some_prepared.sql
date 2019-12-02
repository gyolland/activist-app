-- select from person role with a pair of person ids
PREPARE s_p_role_pair
FROM
    'SELECT * FROM t_person_role WHERE person_id IN (?, ?)';

-- select from t_address with a pair of person ids
PREPARE s_add_pair
FROM
    'SELECT * FROM t_address WHERE person_id IN (?, ?)';

-- find duplicates
PREPARE s_dupes
FROM
    'SELECT 
        p.id
    , p.fname
    , p.lname
    , p.ocvr_voter_id
    , r0.role_id
    , r0.term_start_date
    , r0.term_end_date
    , r0.elected
    , r.role_name
    -- , p.*
    FROM t_person p 
    JOIN 
        (SELECT fname, lname, count(*) AS recs 
            FROM t_person 
        GROUP BY fname, lname
        HAVING count(*) > 1 ) n ON p.fname = n.fname AND p.lname = n.lname
    LEFT JOIN t_person_role r0 ON p.id = r0.person_id
    JOIN t_role r ON r0.role_id = r.id
    ORDER BY p.lname, p.fname, p.id';

-- update t_person_role by person role id
PREPARE u_p_role
FROM
   'UPDATE t_person_role 
    SET term_end_date = ?
      , inactive = ?
    WHERE id = ?' ;