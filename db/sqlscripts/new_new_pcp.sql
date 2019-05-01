SELECT
      o.precinct
    , o.ocvr_voter_id
    , f_get_word_part(o.fname, 1) AS fname
    , trim(o.lname) AS lname
    , f_get_word_part(o.fname, 2) AS middlename
    , right(o.status_gender, 1) AS gender
    , o.assignment
FROM t_import_ocvr_tmp o
LEFT JOIN ( SELECT p.id, p.ocvr_voter_id, r0.term_start_date, r0.term_end_date
              FROM t_person p
              JOIN t_person_role r0 ON p.id = r0.person_id
             WHERE r0.role_id = 3
               AND r0.inactive = false ) p USING( ocvr_voter_id )
WHERE p.id is NULL ;