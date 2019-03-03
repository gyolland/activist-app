LOAD DATA LOCAL INFILE 'vanpcpmin.csv'
    INTO TABLE t_import_pcp_van_min_tmp
    FIELDS TERMINATED BY ','
	OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(   ocvr_voter_id
  , vanid
  , lname
  , fname
  , middlename
  , suffix
  , nickname
  , cd
  , sd
  , hd
  , preferred_email
  , preferred_phone
  , vanprecinct
  );
