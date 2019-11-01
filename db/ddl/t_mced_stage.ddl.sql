
CREATE TABLE t_mced_stage (
  id          int(11) NOT NULL auto_increment,
  fname       varchar(40) NOT NULL,
  middlename  varchar(40) DEFAULT NULL,
  lname       varchar(40) NOT NULL,
  precinct    int(11) DEFAULT NULL,
  m_address   varchar(100) DEFAULT NULL,
  m_zip       varchar(15) DEFAULT NULL,
  PRIMARY KEY (id)
);
