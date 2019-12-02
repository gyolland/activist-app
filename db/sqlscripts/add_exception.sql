-- turn this into a procedure
insert into exception
select 
    p.id
  , p.fname
  , p.middlename
  , p.lname
  , m.fname d_fname
  , m.middlename d_middlename
  , m.lname d_lname
  , f_skey(m.fname, m.middlename, m.lname) skey_long
  , f_skey(m.fname, null, m.lname) skey_short
from t_person p 
join	member_stage m ON p.id = m.member_id 
where p.id = 948 ;