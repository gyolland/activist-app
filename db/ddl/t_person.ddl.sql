CREATE TABLE `t_person` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `precinct` int(11) DEFAULT NULL,
  `cd` int(11) DEFAULT NULL COMMENT 'Congressional District',
  `ocvr_voter_id` varchar(12) DEFAULT NULL,
  `vanid` varchar(20) DEFAULT NULL,
  `fname` varchar(40) NOT NULL,
  `lname` varchar(40) NOT NULL,
  `middlename` varchar(40) DEFAULT NULL,
  `nickname` varchar(40) DEFAULT NULL,
  `gender` char(1) DEFAULT NULL,
  `primary_phone` varchar(40) DEFAULT NULL,
  `allow_text` int(11) DEFAULT '0' COMMENT 'Flag to indicate whether sending text messages to the phone number is allowed.',
  `primary_email` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=916 DEFAULT CHARSET=latin1