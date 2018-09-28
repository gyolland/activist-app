CREATE TABLE `t_import_ocvr_tmp` (
  `tmp_id` int(11) NOT NULL AUTO_INCREMENT,
  `precinct` int(11) DEFAULT NULL,
  `gender` varchar(10) DEFAULT NULL,
  `ocvr_voter_id` varchar(14) DEFAULT NULL,
  `lname` varchar(40) DEFAULT NULL,
  `fname` varchar(40) DEFAULT NULL,
  `m_address` varchar(100) DEFAULT NULL,
  `m_city` varchar(40) DEFAULT NULL,
  `m_state` char(2) DEFAULT NULL,
  `m_zip` varchar(15) DEFAULT NULL,
  `r_address` varchar(100) DEFAULT NULL,
  `r_city` varchar(40) DEFAULT NULL,
  `r_state` char(2) DEFAULT NULL,
  `r_zip` varchar(15) DEFAULT NULL,
  `status_gender` varchar(5) DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `assignment` varchar(40) DEFAULT NULL,
  PRIMARY KEY (`tmp_id`),
  UNIQUE KEY `precinct_UNIQUE` (`tmp_id`)
) ENGINE=InnoDB AUTO_INCREMENT=735 DEFAULT CHARSET=latin1