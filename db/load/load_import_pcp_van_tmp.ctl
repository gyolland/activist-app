LOAD DATA LOCAL INFILE 'vanpcp.csv'
    INTO TABLE t_import_pcp_van_tmp
    FIELDS TERMINATED BY ','
	OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(   vanid
  , vanprecinct
  , mcedprecinct
  , lname
  , fname
  , middlename
  , suffix
  , nickname
  , gender
  , r_address
  , r_city
  , r_state
  , r_zip
  , r_zip4
  , r_country_code
  , email
  , phone2
  , phone
  , phone3
  , m_address
  , m_city
  , m_state
  , m_zip
  , m_zip4
  , cd
  , @discard -- senate district
  , @discard -- house distrct
  );
