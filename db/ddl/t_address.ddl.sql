-- ----------------------------------------------------------------------------
-- Table t_address
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS t_address (
  person_id   INT(11)       NOT NULL  DEFAULT '0',
  type        VARCHAR(4)    NOT NULL  DEFAULT 'RESI',
  address     VARCHAR(100)  NULL      DEFAULT NULL,
  city        VARCHAR(40)   NULL      DEFAULT NULL,
  state       VARCHAR(2)    NULL      DEFAULT 'OR',
  zip5        VARCHAR(5)    NULL      DEFAULT NULL,
  zip4        VARCHAR(4)    NULL      DEFAULT NULL,
  PRIMARY KEY (person_id, type),
  CONSTRAINT FK_PERSON_ADDRESS
  FOREIGN KEY (person_id)
    REFERENCES t_person (id)
    ON DELETE CASCADE
    ON UPDATE NO ACTION
);
