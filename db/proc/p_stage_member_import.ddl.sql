DROP PROCEDURE IF EXISTS p_stage_member_import;

DELIMITER //

CREATE PROCEDURE p_stage_member_import (IN p_report_only BOOLEAN, IN p_report_date DATE)
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE onError INT DEFAULT FALSE;

    DECLARE v_member_id     INT         DEFAULT NULL;
    DECLARE v_inactive      BOOLEAN     DEFAULT FALSE;

    -- t_imp_mced_xl columns
    DECLARE l_precinct INT DEFAULT NULL;
    DECLARE l_position VARCHAR(40) DEFAULT NULL;
    DECLARE l_voter_id VARCHAR(14) DEFAULT NULL;
    -- DECLARE fname, middlename, lname, m_city, r_city, assignment VARCHAR(40) DEFAULT NULL;
    DECLARE l_fname, l_middlename, l_lname, l_m_city, l_r_city, l_assignment VARCHAR(40) DEFAULT NULL;
    DECLARE l_suffix, l_gender VARCHAR(10) DEFAULT NULL;
    DECLARE l_m_address, l_r_address VARCHAR(100) DEFAULT NULL;
    DECLARE l_m_state, l_r_state VARCHAR(2) DEFAULT NULL;
    DECLARE l_m_zip, l_r_zip CHAR(15) DEFAULT NULL;
    DECLARE l_status_gender VARCHAR(5) DEFAULT NULL;
    -- DECLARE l_status VARCHAR(20) DEFAULT NULL;
    DECLARE l_party VARCHAR(15) DEFAULT NULL;
    -- DECLARE l_phone VARCHAR(20) DEFAULT NULL;
    DECLARE l_status, l_phone, l_start_date_str, l_end_date_str VARCHAR(20) DEFAULT NULL;

    DECLARE c_imp CURSOR FOR
    SELECT  fname, middlename, lname, suffix, precinct, voter_id, m_address, m_city, m_state, m_zip, 
    	    status, start_date_str, end_date_str, position, party
      FROM t_imp_mced_xl ;
    -- DECLARE c_imp CURSOR FOR
    -- SELECT  fname, middlename, lname, suffix, precinct
    --   FROM t_imp_mced_xl LIMIT 5;


    -- condition/exception handlers
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        GET CURRENT DIAGNOSTICS CONDITION 1
            @errno = MYSQL_ERRNO, @msg = MESSAGE_TEXT;

        ROLLBACK;

        SET @_act = 'ERROR';
        SET @_msg = CONCAT(@errno, ': ', @msg);

        SET onError = TRUE;

        -- person_id, person_role_id, action, logmessage
        EXECUTE insert_change_log USING @_pid, @_prid, @_act, @_msg;
    END;

    -- prepared statements
    PREPARE insert_change_log
    FROM
        'INSERT INTO t_change_log(person_id, person_role_id, action, logmessage) VALUES (?, ?, ?, ?)';

    PREPARE insert_member
    FROM
        'INSERT INTO member_stage( member_id, precinct, voter_id, fname, middlename, lname, suffix,
         r_address, r_city, r_state, r_zip, status_gender, assignment, start_date, end_date, skey_long, skey_short ) 
         VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)';
    -- PREPARE insert_member
    -- FROM
    --     'INSERT INTO member_stage( member_id, fname, middlename, lname, suffix )
    --      VALUES(?, ?, ?, ?, ?)';



    OPEN c_imp;

    memloop: LOOP
        SET onError = FALSE;

        -- SET @_pid = 1;
        -- SET @_act = 'CHECK';
        -- SET @_msg = CONCAT('Top of the loop before fecth. onError = ', onError);
        -- EXECUTE insert_change_log USING @_pid, @_prid, @_act, @_msg;

        FETCH c_imp INTO l_fname, l_middlename, l_lname, l_suffix, l_precinct, l_voter_id, 
        l_m_address, l_m_city, l_m_state, l_m_zip, l_status, l_start_date_str, l_end_date_str, 
        l_position, l_party;
        -- FETCH c_imp INTO l_fname, l_middlename, l_lname, l_suffix, l_precinct ;
            IF done = TRUE THEN
                leave memloop;
            END IF;

        SET @member_id = NULL;
        -- SET @_pid = 2;
        -- SET @_act = 'CHECK';
        -- SET @_msg = CONCAT('After fecth, before error check. onError = ', onError);
        -- EXECUTE insert_change_log USING @_pid, @_prid, @_act, @_msg;
        -- SET @_pid = 2;
        -- SET @_act = 'CHECK';
        -- SET @_msg = CONCAT(l_m_address, l_m_city, l_m_state, l_m_zip);
        -- EXECUTE insert_change_log USING @_pid, @_prid, @_act, @_msg;

        IF onError = TRUE THEN
            ITERATE memloop;
        END IF;

        -- SET @_pid = 3;
        -- SET @_act = 'CHECK';
        -- SET @_msg = CONCAT('After error check, before variable SETs. onError = ', onError);
        -- EXECUTE insert_change_log USING @_pid, @_prid, @_act, @_msg;

        SET @skey_long      = f_skey(l_fname, l_middlename, l_lname);
        SET @skey_short     = f_skey(l_fname, '', l_lname);
        SET @member_id      = f_skey_to_member_id(@skey_long, @skey_short);

        -- SET @_pid = 0;
        -- SET @_act = 'CHECK';
        -- SET @_msg = CONCAT('Values: ', @skey_long);
        -- EXECUTE insert_change_log USING @_pid, @_prid, @_act, @_msg;

        SET @fname          = TRIM(l_fname);
        SET @middlename     = TRIM(l_middlename);
        SET @lname          = TRIM(l_lname);
        SET @suffix         = TRIM(l_suffix);
        SET @precinct       = l_precinct;
        SET @voter_id       = TRIM(l_voter_id);
        SET @r_address      = TRIM( l_m_address );
        SET @r_city         = TRIM( l_m_city );
        SET @r_state        = TRIM( l_m_state );
        SET @r_zip          = TRIM( l_m_zip );
        SET @assignment     = TRIM( CONCAT(l_status, ' ', l_start_date_str) );
        SET @start_date     = STR_TO_DATE(l_start_date_str, '%m/%e/%Y');
        SET @end_date       = STR_TO_DATE(l_end_date_str, '%m/%e/%Y');

        START TRANSACTION;

        -- SET @_pid = 4;
        -- SET @_act = 'CHECK';
        -- SET @_msg = CONCAT('After START TRANSACTION before insert_member. onError = ', onError);
        -- EXECUTE insert_change_log USING @_pid, @_prid, @_act, @_msg;

        EXECUTE insert_member USING 
        @member_id, @precinct, @voter_id, @fname, @middlename, @lname, 
        @suffix, @r_address, @r_city, @r_state , @r_zip, @status_gender, 
        @assignment, @start_date, @end_date, @skey_long, @skey_short;
        -- EXECUTE insert_member USING @member_id, @fname, @middlename, @lname, @suffix ;

        IF onError = TRUE THEN
            ITERATE memloop;
        END IF;

        -- SET @_pid = 5;
        -- SET @_act = 'CHECK';
        -- SET @_msg = CONCAT('Before COMMIT. onError = ', onError);
        -- EXECUTE insert_change_log USING @_pid, @_prid, @_act, @_msg;

        COMMIT;
    END LOOP; -- memloop

    CLOSE c_imp;

    -- deallocate prepared statements
    DEALLOCATE PREPARE insert_change_log;
    DEALLOCATE PREPARE insert_member;
END //

DELIMITER ;