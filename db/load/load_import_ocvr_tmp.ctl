LOAD DATA LOCAL INFILE 'ocvr.csv'
    INTO TABLE t_import_ocvr_tmp
    FIELDS TERMINATED BY ','
	OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(   precinct
  , gender
  , ocvr_voter_id
  , lname
  , fname
  , m_address
  , m_city
  , m_state
  , m_zip
  , r_address
  , r_city
  , r_state
  , r_zip
  , status_gender
  , phone
  , assignment
  );
