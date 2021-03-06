CREATE TABLE member_stage (
  stg_id          int(11)       AUTO_INCREMENT NOT NULL,
  member_id       int(11)       DEFAULT NULL,
  precinct        int(11)       DEFAULT NULL,
  gender          varchar(10)   DEFAULT NULL,
  voter_id        varchar(14)   DEFAULT NULL,
  fname           varchar(40)   DEFAULT NULL,
  middlename      varchar(40)   DEFAULT NULL,
  lname           varchar(40)   DEFAULT NULL,
  suffix          varchar(10)   DEFAULT NULL,
  m_address       varchar(100)  DEFAULT NULL,
  m_city          varchar(40)   DEFAULT NULL,
  m_state         char(2)       DEFAULT NULL,
  m_zip           varchar(15)   DEFAULT NULL,
  r_address       varchar(100)  DEFAULT NULL,
  r_city          varchar(40)   DEFAULT NULL,
  r_state         char(2)       DEFAULT NULL,
  r_zip           varchar(15)   DEFAULT NULL,
  status_gender   varchar(20)    DEFAULT NULL,
  phone           varchar(20)   DEFAULT NULL,
  assignment      varchar(40)   DEFAULT NULL,
  start_date      date          DEFAULT NULL,
  end_date        date          DEFAULT NULL,
  skey_long       varchar(120)  DEFAULT NULL,
  skey_short      varchar(120)  DEFAULT NULL,
  PRIMARY KEY stg_pk_idx (stg_id),
  KEY member_idx (member_id),
  KEY skey1_idx (skey_long),
  KEY skey2_idex (skey_short),
  UNIQUE KEY stg_unique (stg_id)
);
