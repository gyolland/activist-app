create table import_ocvr2022_tmp (
    id int NOT NULL AUTO_INCREMENT
  , `PRECINCT` varchar(4)
  , `VOTER ID` varchar(10)
  , `LAST NAME` varchar(40)
  , `FIRST NAME` varchar(40)
  , `MAILING STREET ADDRESS` varchar(40)
  , `MAILING CITY` varchar(40)
  , `MAILING STATE` varchar(2)
  , `MAILING ZIP` varchar(10)
  , `PHYSICAL ADDRESS` varchar(40)
  , `PHYSICAL CITY` varchar(40)
  , `PHYSICAL STATE` varchar(2)
  , `PHYSICAL ZIP` varchar(10)
  , `STATUS` varchar(2)
  , `PHONE` varchar(20)
  , `ASSIGNMENT` varchar(20)
  , primary key(id)
 ) ;