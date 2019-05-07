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
    DECLARE v_fname, v_lname, v_middlename VARCHAR(40);
    DECLARE gender VARCHAR(10);
    DECLARE v_gender1 CHAR(1);
    DECLARE precinct INT DEFAULT NULL;
    DECLARE r_address, m_address VARCHAR(100);
    DECLARE r_city, m_city VARCHAR(40);
    DECLARE r_zip, m_zip VARCHAR(15);
    
    -- fields needed for t_person_role
    DECLARE term_start_date DATE;
    DECLARE v_elected INT DEFAULT FALSE;

    DECLARE c_pcp CURSOR FOR
    SELECT o.fname, o.lname, o.gender, o.precinct, o.ocvr_voter_id, o.assignment,
        o.r_address, o.r_city, o.r_zip, o.m_address, o.m_city, o.m_zip
      FROM t_import_ocvr_tmp o 
      LEFT JOIN t_person p USING(ocvr_voter_id)
     WHERE p.id IS NULL ;

    -- condition/exception handlers
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        GET CURRENT DIAGNOSTICS CONDITION 1
            errno = MYSQL_ERRNO, msg = MESSAGE_TEXT;
        SET v_error = errno;

        ROLLBACK;

        INSERT INTO t_change_log(person_id, action, logmessage)
        VALUES (v_person_id, 'ERROR', CONCAT(errno, ': ', msg));
    END;

    OPEN c_pcp;

    newpcp LOOP
    -- add PCP to t_person, collect t_person_id
        -- first, middle, last name, gender, precinct, ocvr_voter_id, assignment
        FETCH  c_pcp INTO fname, lname, gender, precinct, ocvr_voter_id, assignment,
            r_address, r_city, r_zip, m_address, m_city, m_zip;

        START TRANSACTION;
        SET v_fname = f_get_word_part(fname, 1);
        SET v_middlename = f_get_word_part(fname, 2);
        SET v_lname = TRIM(lname);
        SET v_gender1 = LEFT(TRIM(gender), 1);

        INSERT INTO t_person (fname, lname, gender, precinct, ocvr_voter_id, assignment)
        VALUES (v_fname, v_middlename, v_lname, v_gender1, precinct, ocvr_voter_id, assignment);

        --  capture t_person id
        SET v_person_id = LAST_INSERT_ID();

        -- add t_person_role records
        IF INSTR(assignment, 'elect') > 0 THEN
            SET v_elected = TRUE;
        END IF;

        SET term_start_date = f_get_assignment_date(assignment);

        INSERT INTO t_person_role(person_id, role_id, certified_pcp, elected, term_start_date, term_end_date, inactive)
        VALUES(v_person_id, 3, TRUE, v_elected, term_start_date, p_term_end_date, FALSE);

        -- add address records - both resi & mail
        SET r_address = TRIM(r_address);
        SET r_city = TRIM(r_city);

        INSERT INTO t_address (person_id, type, address, city, state, zip5, zip4)
        VALUES(v_person_id, 'RESI', )


        -- PCP application: email, phone 

        -- VAN: VANID, CD, vanprecinct

        IF done = TRUE THEN
            leave newpcp;
        END IF;    

        SET elected = FALSE;
    END LOOP; -- newpcp

    CLOSE c_pcp;
END$$

DELIMITER ;