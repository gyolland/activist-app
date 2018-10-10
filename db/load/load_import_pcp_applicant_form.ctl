LOAD DATA LOCAL INFILE 'pcp_form.csv'
    INTO TABLE t_import_pcp_applicant_form
    FIELDS TERMINATED BY ',' 
	OPTIONALLY ENCLOSED BY '"' 
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(	
    precinct 
  , appl_timestamp
  , fname
  , lname
  , r_address
  , r_city
  , r_zip
  , email
  , phone
  , bio
  , experience
  , motivation
  , gender
);