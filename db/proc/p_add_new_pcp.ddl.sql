DROP PROCEDURE IF EXISTS p_add_new_pcp;

DELIMITER $$

CREATE PROCEDURE p_add_new_pcp (p_term_end_date DATE)
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_error INT DEFAULT FALSE;
    DECLARE errno INT;
    DECLARE msg TEXT;
    DECLARE v_person_id INT;
    DECLARE v_action VARCHAR(20) DEFAULT 'ADDED';
    DECLARE v_logmsg VARCHAR(255) DEFAULT 'PCP newly added on based on MCED data ';

    -- OCVR fields
    DECLARE ocvr_voter_id VARCHAR(12);
    DECLARE fname, lname, assignment VARCHAR(40);
    DECLARE gender VARCHAR(10);
    DECLARE precinct INT DEFAULT NULL;
    DECLARE r_address, m_address VARCHAR(100);
    DECLARE r_city, m_city VARCHAR(40);
    DECLARE r_zip, m_zip VARCHAR(15);
    
    -- fields needed for t_person_role
    DECLARE term_start_date DATE;

    -- CURSOR: select new PCPs from MCED data

    -- condition/exception handlers
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET v_error = TRUE;

    OPEN c_pcp;

    newpcp LOOP
    -- add PCP to t_person, collect t_person_id
        -- first, middle, last name, gender, precinct, ocvr_voter_id, assignment

    --  capture t_person id
    SET v_person_id = LAST_INSERT_ID();

    -- add t_person_role records

    -- add address records - both resi & mail

    -- PCP application: email, phone 

    -- VAN: VANID, CD, vanprecinct

        IF done THEN
            leave newpcp;
        END IF;    
    END LOOP; -- newpcp

    CLOSE c_pcp;
END$$

DELIMITER ;