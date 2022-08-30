create table t_hd44 (
    ID int auto_increment 
  , FirstName varchar(30)
  , LastName varchar(30)
  , Nickname varchar(30)
  , Precinct varchar(10)
  , Address varchar(100)
  , ZipCode varchar(10) 
  , Email varchar(100)
  , Phone varchar(100)
  , PCP2022 varchar(6)
  , extra1 varchar(100)
  , extra2 varchar(100)
  , extra3 varchar(100)
  , DoNotText bit default 0
  , DoNotCall bit default 0
  , EmailBounced bit default 0
  , BounceDate date
  , slate bit default 0
  , primary key(id)
) ;