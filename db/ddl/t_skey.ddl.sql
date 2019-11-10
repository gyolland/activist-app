/********************************************************************************
t_skey: table to store surrogate keys and intended to be used to join imported
        data with existing data. This is needed because all data sources do not
        always provide reliable keys. These surrogate keys will not be 100% 
        reliable either but should provide a high likelyhood  of matching.
********************************************************************************/
CREATE TABLE t_skey (
  tmp_id        int(11)         DEFAULT '0',
  person_id     int(11)         NOT NULL DEFAULT '0',
  fname         varchar(40)     NOT NULL,
  middlename    varchar(40)     DEFAULT NULL,
  lname         varchar(40)     NOT NULL,
  skey_long     varchar(120)    DEFAULT NULL,
  skey_short    varchar(80)     DEFAULT NULL,
  PRIMARY KEY (person_id)
) ENGINE=InnoDB ;