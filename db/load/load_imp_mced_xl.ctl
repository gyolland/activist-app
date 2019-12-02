LOAD DATA  INFILE '/var/lib/mysql-files/mced_xl.csv'
    REPLACE
    INTO TABLE t_imp_mced_xl
    FIELDS TERMINATED BY ','
	OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(   precinct
  , position
  , @voter_id 
  , fname 
  , middlename 
  , lname
  , suffix
  , m_address
  , m_city
  , @m_state
  , m_zip
  , party
  , status
  , @start_date
  , @end_date
)
SET voter_id = CASE WHEN LENGTH(TRIM(@voter_id))>0 THEN TRIM(@voter_id) ELSE NULL END
  , m_state = TRIM(@m_state)
  , start_date_str = @start_date
  , end_date_str = @end_date
  , start_date = str_to_date(@start_date, '%m/%e/%Y') --  6/8/2018
  , end_date = str_to_date(@end_date, '%m/%e/%Y')
;
