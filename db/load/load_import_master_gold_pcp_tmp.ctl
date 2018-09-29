LOAD DATA LOCAL INFILE 'master_pcp.csv'
    INTO TABLE t_import_master_gold_pcp_tmp
    FIELDS TERMINATED BY ',' 
	OPTIONALLY ENCLOSED BY '"' 
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(    vanid
   , vanprecinct
   , mcedprecinct
   , cd
   , lname
   , fname
   , middlename
   , nickname
   , suffix
   , gender
   , pcp_elected_appointed
   , r_address
   , r_city
   , r_state
   , r_zip
   , r_zip4
   , r_country_code
   , email
   , phone1
   , phone1_allow_text
   , phone2
   , phone2_allow_text
   , m_address
   , m_city
   , m_state
   , m_zip
   , assignment
);