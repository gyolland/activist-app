LOAD DATA LOCAL INFILE '/private/var/lib/mysql_load/ocvr.csv'
    INTO TABLE import_ocvr2022_tmp
    FIELDS TERMINATED BY ','
	OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(   
    `PRECINCT`
  , `VOTER ID`
  , `LAST NAME`
  , `FIRST NAME`
  , `MAILING STREET ADDRESS`
  , `MAILING CITY`
  , `MAILING STATE`
  , `MAILING ZIP`
  , `PHYSICAL ADDRESS`
  , `PHYSICAL CITY`
  , `PHYSICAL STATE`
  , `PHYSICAL ZIP`
  , `STATUS`
  , `PHONE`
  , `ASSIGNMENT`
  );
