-- ----------------------------------------------------------------------------
-- Table error_log
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS error_log (
    id              INT(11) NOT NULL AUTO_INCREMENT,
    changed         TIMESTAMP DEFAULT current_timestamp(),
    person_id       INT(11),
    logmessage      text,
    PRIMARY KEY(id) 
);