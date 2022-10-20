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
  , DoNotText bit(1) not null default 0
  , DoNotCall bit(1) not null default 0
  , EmailBounced bit(1) not null default 0
  , BounceDate date
  , slate bit default 0
  , unsubscribed bit(1) not null default 0
  , pillar bit(1) not null default 0
  , last_donation_date date default null
  , primary key(id)
) ;