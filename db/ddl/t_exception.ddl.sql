CREATE TABLE t_exception (
  person_id         int(11) NOT NULL DEFAULT '0',
  fname             varchar(40) NOT NULL,
  middlename        varchar(40) DEFAULT NULL,
  lname             varchar(40) NOT NULL,
  d_fname           VARCHAR(40) DEFAULT NULL,
  d_middlename      VARCHAR(40) DEFAULT NULL,
  d_lname           VARCHAR(40) DEFAULT NULL,
  skey_long         varchar(120) DEFAULT NULL,
  skey_short        varchar(120) DEFAULT NULL,
  PRIMARY KEY pk_person_id (person_id) 
) ;