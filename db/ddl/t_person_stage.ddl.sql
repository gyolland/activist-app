-- t_person_stage: 
-- this table is meant to be temporary storage used to build up
-- t_person records from several different sources. The primary is the OCVR data
-- received from the county. Then data gets enhanced with data from PCP Applicant
-- Form and VAN. Possibly other (i.e., volunteer) sources.
CREATE TABLE t_person_stage (
  id int(11) NOT NULL ,
  vanprecinct     varchar(40) DEFAULT NULL,
  precinct        int(11) DEFAULT NULL,
  cd              tinyint(4) DEFAULT NULL COMMENT 'Congressional District',
  ocvr_voter_id   varchar(12) DEFAULT NULL,
  vanid           varchar(20) DEFAULT NULL,
  fname           varchar(40) NOT NULL,
  lname           varchar(40) NOT NULL,
  middlename      varchar(40) DEFAULT NULL,
  nickname        varchar(40) DEFAULT NULL,
  suffix          varchar(8) DEFAULT NULL,
  gender          char(1) DEFAULT NULL,
  primary_phone   varchar(40) DEFAULT NULL,
  allow_text1     tinyint(4) DEFAULT '0' COMMENT 'Flag to indicate whether sending text messages to the primary phone number is allowed.',
  phone2          varchar(40) DEFAULT NULL,
  allow_text2     tinyint(4) DEFAULT '0' COMMENT 'Flag to indicate whether sending text messages to the phone2 number is allowed.',
  primary_email   varchar(100) DEFAULT NULL,
  nda_on_file     boolean DEFAULT FALSE,
  assignment      varchar(40) DEFAULT NULL,
  PRIMARY KEY (id)
);