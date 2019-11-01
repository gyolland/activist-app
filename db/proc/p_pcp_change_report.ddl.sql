DROP PROCEDURE IF EXISTS p_pcp_change_report;

DELIMITER //

CREATE PROCEDURE p_add_new_pcp (p_date_of_report DATE)
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE onError INT DEFAULT FALSE;

    DECLARE c_timestamp TIMESTAMP DECLARE current_timestamp();

    DECLARE o_state_vid VARCHAR(14) DEFAULT NULL;
    DECLARE o_precinct INT ;
    DECLARE o_lname, o_fname, o_mcity, o_rcity, o_assignment VARCHAR(40);
    DECLARE o_maddress, o_raddress VARCHAR(100);
    DECLARE o_mstate, o_rstate VARCHAR(2);
    DECLARE o_mzip, o_rzip VARCHAR(15);
    DECLARE o_gender VARCHAR(10);
    DECLARE o_status_gender VARCHAR(5);
    DECLARE o_phone VARCHAR(20);

    DECLARE person_id INT;
    DECLARE precinct_change, address_change, returning_pcp, new_pcp, removed_pcp BOOLEAN DEFAULT FALSE;

    DECLARE c_current_pcp CURSOR FOR
    SELECT  
        p.id, p.ocvr_voter_id, p.precinct, p.gender, p.ocvr_voter_id, lname, fname, 
        a.address AS r_address, a.city AS r_city, 
        CONCAT(a.zip5, CASE  WHEN a.zip4 IS NULL THEN '' ELSE CONCAT('-', a.zip4) END) AS r_zip,
        p.primary_phone, p.primary_email, p.assignment
      FROM t_person p 
      JOIN (SELECT * FROM t_person_role WHERE role_id = 3 AND inactive = FALSE) r0 ON p.id = r0.person_id
      JOIN (SELECT * FROM t_address WHERE type = 'RESI') a ON p.id = a.person_id;

    -- DECLARE c_new_pcp CURSOR FOR
    DECLARE c_ocvr_pcp CURSOR FOR
    SELECT 
        ocvr_voter_id, lname, fname, precinct, gender, m_address, m_city, m_state, m_zip, 
        r_address, r_city, r_state, r_zip, status_gender, phone, assignment
      FROM t_import_ocvr_tmp;

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

    SET @report_date = p_date_of_report;

    -- prepared statements
    PREPARE insert_change_log
    FROM
        'INSERT INTO t_change_log(person_id, person_role_id, action, logmessage) VALUES (?, ?, ?, ?)';



    -- design decision
    -- drive process off OCVR data
    
    -- * +all relevent PCPs identified except those no longer in report
    -- * +newly inactive PCPs, those no longer in the report are easily ID'd 
    -- *- newly inactive PCPs require additional processing
    OPEN c_ovcr_pcp;
    ovcr: LOOP
      SET onError = FALSE;

      FETCH c_ocvr_pcp INTO o_state_vid, o_lname, o_fname, o_precinct, o_gender, 
        o_maddress, o_mcity, o_mstate, o_mzip, o_raddress, o_rcity, o_rstate, o_rzip
        o_status_gender, o_phone, o_assignment;
        IF done = TRUE THEN
            leave ocvr;
        END IF;
           
      -- query t_person with state voter id
    END LOOP; -- ocvr
    
END //

DELIMITER ;
