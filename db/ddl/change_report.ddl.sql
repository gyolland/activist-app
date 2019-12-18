CREATE TABLE change_report (
    id              INT(11) AUTO_INCREMENT
  , stg_id          INT(11) DEFAULT NULL
  , report_date     DATE DEFAULT NULL
  , person_id       INT(11) DEFAULT NULL
  , category        VARCHAR(100) DEFAULT NULL
  , message         TEXT DEFAULT NULL
  , PRIMARY KEY rpt_pk_idx (id)
  , KEY person_idx (person_id)
  , UNIQUE KEY rpt_unique (id)
);