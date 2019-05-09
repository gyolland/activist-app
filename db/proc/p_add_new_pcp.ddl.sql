DROP PROCEDURE IF EXISTS p_add_new_pcp;

DELIMITER //

CREATE PROCEDURE p_add_new_pcp (p_term_end_date DATE, p_date_of_report DATE)
BEGIN
    DECLARE done INT DEFAULT FALSE;
    -- DECLARE v_error INT DEFAULT FALSE;
    -- DECLARE errno INT;
    -- DECLARE msg TEXT;
    -- DECLARE v_person_id INT;
    -- DECLARE v_action VARCHAR(20) DEFAULT 'ADDED';
    -- DECLARE v_logmsg VARCHAR(255) DEFAULT 'PCP newly added on based on MCED data ';

    -- OCVR fields
    DECLARE ocvr_voter_id VARCHAR(12);
    -- DECLARE fname, lname, assignment VARCHAR(40);
    DECLARE fname, lname VARCHAR(40);
    -- DECLARE v_fname, v_lname, v_middlename VARCHAR(40);
    DECLARE gender VARCHAR(10);
    -- DECLARE v_gender1 CHAR(1);
    -- DECLARE precinct INT DEFAULT NULL;
    DECLARE r_address, m_address VARCHAR(100);
    DECLARE r_city, m_city VARCHAR(40);
    DECLARE r_zip, m_zip VARCHAR(15);
    DECLARE r_state, m_state VARCHAR(2);
    
    -- fields needed for t_person_role
    -- DECLARE term_start_date DATE;
    -- DECLARE v_elected INT DEFAULT FALSE;

    SET @report_date = p_date_of_report;

    -- prepared statements
    PREPARE insert_change_log
    FROM
        'INSERT INTO t_change_log(person_id, person_role_id, action, logmessage) VALUES (?, ?, ?, ?)';

    PREPARE insert_person
    FROM
        'INSERT INTO t_person (fname, middlename, lname, gender, precinct, ocvr_voter_id, assignment) VALUES (?, ?, ?, ?, ?, ?, ?)';

    PREPARE insert_person_role
    FROM
        'INSERT INTO t_person_role(person_id, role_id, certified_pcp, elected, term_start_date, term_end_date, inactive)
        VALUES(?, ?, ?, ?, ?, ?, ?)';
    
    PREPARE insert_address
    FROM 
        'INSERT INTO t_address (person_id, type, address, city, state, zip5, zip4) VALUES(?, ?, ?, ?, ?, ?, ?)';

    DECLARE c_pcp CURSOR FOR
    SELECT o.fname, o.lname, o.gender, o.precinct, o.ocvr_voter_id, o.assignment,
        o.r_address, o.r_city, o.r_state, o.r_zip, o.m_address, o.m_city, o.m_state, o.m_zip
      FROM t_import_ocvr_tmp o 
      LEFT JOIN t_person p USING(ocvr_voter_id)
     WHERE p.id IS NULL ;

    -- condition/exception handlers
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        GET CURRENT DIAGNOSTICS CONDITION 1
            @errno = MYSQL_ERRNO, @msg = MESSAGE_TEXT;
        --    errno = MYSQL_ERRNO, msg = MESSAGE_TEXT;
        --SET v_error = errno;

        ROLLBACK;

        -- SET @_pid = v_person_id;
        SET @_prid = v_person_role_id;
        SET @_act = 'ERROR';
        SET @_msg = CONCAT(@errno, ': ', @msg);

        -- person_id, person_role_id, action, logmessage
        EXECUTE insert_change_log USING @_pid, @_prid, @_act, @_msg;
    END;

    OPEN c_pcp;

    newpcp LOOP
    -- add PCP to t_person, collect t_person_id
        -- first, middle, last name, gender, precinct, ocvr_voter_id, assignment
        FETCH  c_pcp INTO fname, lname, gender, @precinct, ocvr_voter_id, @assignment,
            r_address, r_city, r_state, r_zip, m_address, m_city, m_state, m_zip;
        IF done = TRUE THEN
            leave newpcp;
        END IF;    
       
        SET @_fname = f_get_word_part(fname, 1);
        SET @_middlename = f_get_word_part(fname, 2);
        SET @_lname = TRIM(lname);
        SET @_gender = LEFT(TRIM(gender), 1);
        SET @_ocvr = TRIM(ocvr_voter_id);

         START TRANSACTION;    
        -- fname, middle, lname, gender, precinct, ocvr_voter_id, assignment
        EXECUTE insert_person USING @_fname, @_middlename, @_lname, @_gender, @precinct, @_ocvr, @assignment;

        --  capture t_person id
        SET @_pid = LAST_INSERT_ID();

        -- add t_person_role records
        IF INSTR(@assignment, 'elect') > 0 THEN
            SET @_elected = TRUE;
        ELSE 
            SET @_elected = FALSE;
        END IF;

        SET @_term_start = f_get_assignment_date(@assignment);

        -- person_id, role_id, certified_pcp, elected, term_start_date, term_end_date, inactive
        SET @role = 3;
        SET @cert = TRUE;
        SET @inact = FALSE;
        EXECUTE insert_person_role USING @_pid, @role, @cert, @_elected, @_term_start, @_term_end, @inact;

        -- capture t_person_role_id
        SET @prid = LAST_INSERT_ID();

        -- add address records - both resi & mail
        -- person_id, type, address, city, state, zip5, zip4
        -- voting/residential
        SET @add_type = 'RESI';
        SET @_address = TRIM(r_address);
        SET @_city = TRIM(r_city);
        SET @state = TRIM(r_state);
        SET @_zip5 = LEFT(TRIM(r_zip), 5);
        SET @_zip4 = CASE WHEN LENGTH(TRIM(r_zip)) > 5 THEN RIGHT(TRIM(r_zip), 4) ELSE NULL END;
        EXECUTE insert_address USING @_pid, @add_type, @_address, @_city, @state, @_zip5, @_zip4;

        IF LENGTH(TRIM(m_address)) > 0 THEN
            -- mailing
            SET @add_type = 'MAIL';
            SET @_address = TRIM(m_address);
            SET @_city = TRIM(m_city);
            SET @state = TRIM(m_state);
            SET @_zip5 = LEFT(TRIM(m_zip), 5);
            SET @_zip4 = CASE WHEN LENGTH(TRIM(m_zip)) > 5 THEN RIGHT(TRIM(m_zip), 4) ELSE NULL END;
            EXECUTE insert_address USING @_pid, @add_type, @_address, @_city, @state, @_zip5, @_zip4;
        END IF;

        -- PCP application: email, phone 

        -- VAN: VANID, CD, vanprecinct

        -- person_id, person_role_id, action, logmessage
        SET @_act = 'ADDED';
        SET @_msg = CONCAT('PCP added with report date: ', @report_date);
        EXECUTE insert_change_log USING @_pid, @_prid, @_act, @_msg;

        COMMIT;
    END LOOP; -- newpcp

    CLOSE c_pcp;

    -- deallocate prepared statements
    DEALLOCATE PREPARE t_change_log;
    DEALLOCATE PREPARE insert_person;
    DEALLOCATE PREPARE insert_person_role;
    DEALLOCATE PREPARE insert_address;
END //

DELIMITER ;