CREATE TABLE `t_person_role` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `person_id` int(11) NOT NULL,
  `role_id` int(11) NOT NULL,
  `certified_pcp` tinyint(1) DEFAULT NULL,
  `elected` tinyint(1) DEFAULT NULL,
  `term_start_date` date DEFAULT NULL,
  `term_end_date` date DEFAULT NULL,
  `inactive` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `role_id` (`role_id`),
  CONSTRAINT `FK_PERSON` FOREIGN KEY (`person_id`) REFERENCES `t_person` (`id`) ON DELETE CASCADE,
  CONSTRAINT `FK_ROLE` FOREIGN KEY (`role_id`) REFERENCES `t_role` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1 ;