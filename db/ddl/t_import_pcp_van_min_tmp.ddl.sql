CREATE TABLE t_import_pcp_van_min_tmp (
  ocvr_voter_id varchar(12) NOT NULL,
  vanid varchar(20) DEFAULT NULL,
  vanprecinct varchar(40) DEFAULT NULL,
  precinct int(11) DEFAULT NULL,
  cd tinyint(4) DEFAULT NULL COMMENT 'Congressional District',
  sd tinyint(4) DEFAULT NULL COMMENT 'State Senate District',
  hd tinyint(4) DEFAULT NULL COMMENT 'State House District',
  lname varchar(40) NOT NULL,
  fname varchar(40) NOT NULL,
  middlename varchar(40) DEFAULT NULL,
  nickname varchar(40) DEFAULT NULL,
  suffix varchar(8) DEFAULT NULL,
  preferred_email varchar(100) DEFAULT NULL,
  preferred_phone varchar(40) DEFAULT NULL,
  PRIMARY KEY (ocvr_voter_id)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
