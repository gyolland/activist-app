CREATE OR REPLACE VIEW v_comparison_columns AS
    SELECT 
          p.id AS person_id
        , p.ocvr_voter_id
        , p.precinct
        , o.precinct AS oprecinct
        , p.gender
        , p.fname
        , o.fname AS ofname
        , p.lname
        , o.lname AS olname
        , a.r_address
        , o.r_address AS or_address
    FROM t_person p 
    JOIN t_import_ocvr_tmp o USING(ocvr_voter_id)
    JOIN (SELECT person_id AS id, address AS r_address, type FROM t_address a WHERE type = 'RESI') a USING(id);