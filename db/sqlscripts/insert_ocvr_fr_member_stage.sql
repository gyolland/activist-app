select * from t_import_ocvr_tmp;
truncate t_import_ocvr_tmp;

-- start: update member stage with exiting ocvr_voter_id from t_person
SELECT
    p.id
  , p.ocvr_voter_id
  , m.voter_id
  , p.fname
  , p.middlename
  , p.lname
  , m.fname AS mfname
  , m.middlename AS mmiddlename
  , m.lname AS mlname
  FROM t_person p 
  JOIN member_stage m ON p.id = m.member_id
 WHERE p.ocvr_voter_id <> m.voter_id;

set sql_safe_updates = 0;

start transaction;
update member_stage m, t_person p
SET m.voter_id = p.ocvr_voter_id
where m.member_id = p.id
and m.voter_id <> p.ocvr_voter_id;

commit;
-- start: update member stage with exiting ocvr_voter_id from t_person

insert into t_import_ocvr_tmp( precinct, ocvr_voter_id, lname, fname, r_address, r_city, r_state, r_zip, assignment)
select 
    m.precinct
  , m.voter_id AS ocvr_voter_id
  , m.lname
  , m.fname
  , m.r_address
  , m.r_city
  , m.r_state
  , m.r_zip
  , m.assignment
FROM member_stage m 