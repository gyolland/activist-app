-- ----------------------------------------------------------------------------
-- Table t_change_log
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS t_change_log (
    id INT(11) NOT NULL AUTO_INCREMENT,
    changed TIMESTAMP DEFAULT current_timestamp(),
    action VARCHAR(20) DEFAULT null,
    person_id INT(11) NOT NULL,
    logmessage VARCHAR(1000),
    PRIMARY KEY(id) 
);

