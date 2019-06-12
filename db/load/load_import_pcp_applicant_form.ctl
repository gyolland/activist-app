LOAD DATA INFILE 'pcpform.csv'
    INTO TABLE t_import_pcp_applicant_form
    FIELDS TERMINATED BY ','
	OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    precinct
  , @appl_timestamp
  , fname
  , lname
  , @gender
  , r_address
  , r_city
  , @state
  , r_zip
  , email
  , @phone
  , bio
  , experience
  , motivation
)
   SET gender = substr(trim(@gender), 1, 1)
   , phone = replace(@phone, '-', '')
;
