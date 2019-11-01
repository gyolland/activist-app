CREATE TABLE t_import_pcp_applicant_form
(
	id 				int(11) NOT NULL AUTO_INCREMENT,
	precinct 		int(11) DEFAULT NULL,
	appl_timestamp 	timestamp,
	fname 			varchar(40) NOT NULL,
	lname 			varchar(40) NOT NULL,
	gender 			char(1) DEFAULT NULL,
	r_address 		VARCHAR(100) NULL DEFAULT NULL,
	r_city 			VARCHAR(40) NULL DEFAULT NULL,
	r_zip 			VARCHAR(12) NULL DEFAULT NULL,
	email 			varchar(100) DEFAULT NULL,
	phone 			varchar(40) DEFAULT NULL,
	bio 			TEXT,
	experience 		TEXT,
	motivation 		TEXT,
	PRIMARY KEY (id)
);