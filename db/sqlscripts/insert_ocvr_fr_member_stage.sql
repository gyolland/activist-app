select * from t_import_ocvr_tmp;
truncate t_import_ocvr_tmp;

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