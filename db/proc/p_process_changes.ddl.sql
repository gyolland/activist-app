DROP PROCEDURE IF EXISTS p_process_changes;

DELIMITER //
/* PROCEDURE: p_process_changes - read the member_stage table filtered by records in change_report table
** and apply changes.
*/

CREATE PROCEDURE p_process_changes(IN p_report_date DATE)
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE onError INT DEFAULT FALSE;

    DECLARE v_person_id INT DEFAULT NULL;
    DECLARE v_inactive BOOLEAN DEFAULT FALSE;

    DECLARE l_stg_id, l_member_id, l_precinct INT DEFAULT NULL;
    DECLARE l_fname, l_midname, l_lname, l_city, l_assignment VARCHAR(40) DEFAULT NULL;
    DECLARE l_suffix VARCHAR(10) DEFAULT NULL;
    DECLARE l_voter_id VARCHAR(14) DEFAULT NULL;
    DECLARE l_address, l_category VARCHAR(100) DEFAULT NULL;
    DECLARE l_state CHAR(2) DEFAULT NULL;
    DECLARE l_zip VARCHAR(15) DEFAULT NULL;
    DECLARE l_start_date, l_end_date DATE DEFAULT NULL;

    DECLARE c_unmatched     VARCHAR(30) DEFAULT 'UNMATCHED';
    DECLARE c_inactive      VARCHAR(30) DEFAULT 'INACTIVE';
    DECLARE c_returning     VARCHAR(30) DEFAULT 'RETURNING';
    DECLARE c_current       VARCHAR(30) DEFAULT 'CURRENT';
    DECLARE c_removed       VARCHAR(40) DEFAULT 'REMOVED';
    DECLARE c_precinct      VARCHAR(40) DEFAULT 'PRECINCT';
    DECLARE c_address       VARCHAR(40) DEFAULT 'ADDRESS';
    DECLARE c_new           VARCHAR(40) DEFAULT 'NEW';
    DECLARE c_res_add_typ   VARCHAR(4)  DEFAULT 'RESI';
    DECLARE c_pcp_role      INT         DEFAULT 3;
    DECLARE c_elected       VARCHAR(40) DEFAULT 'Elected';

    DECLARE c_upd CURSOR FOR
    SELECT -- select records where change report has person_id
        m.stg_id, m.member_id, m.fname, m.middlename, m.lname, m.suffix, m.precinct, 
        m.voter_id, m.r_address, m.r_city, m.r_state, m.r_zip, m.assignment, 
        m.start_date, m.end_date, cr.category
      FROM member_stage m
      JOIN(SELECT stg_id, person_id, report_date, category 
             FROM change_report 
            WHERE person_id IS NOT NULL) cr ON m.member_id = cr.person_id
     WHERE cr.report_date = p_report_date   
    UNION
    SELECT -- get new pcps as ID'd by null person_id in change report
        m.stg_id, m.member_id, m.fname, m.middlename, m.lname, m.suffix, m.precinct, 
        m.voter_id, m.r_address, m.r_city, m.r_state, m.r_zip, m.assignment, 
        m.start_date, m.end_date, cr.category
    FROM member_stage m
    JOIN (SELECT stg_id, person_id, report_date, category
            FROM change_report 
           WHERE person_id IS NULL)  cr USING(stg_id)
    WHERE cr.report_date = p_report_date
    UNION
      SELECT -- get data for removed pcps
        null AS stg_id, p.id AS member_id, p.fname, p.middlename, p.lname, p.suffix, p.precinct, 
        p.ocvr_voter_id AS voter_id, null AS r_address, null AS r_city, null AS r_state, null AS r_zip, p.assignment, 
        null AS start_date, p_report_date AS end_date, cr.category
    FROM t_person p 
    JOIN (SELECT stg_id, person_id, report_date, category
            FROM change_report 
           WHERE category = c_removed) cr ON p.id = cr.person_id
    WHERE cr.report_date = p_report_date;

    -- condition/exception handlers
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        GET CURRENT DIAGNOSTICS CONDITION 1
            @errno = MYSQL_ERRNO, @msg = MESSAGE_TEXT;

        ROLLBACK;

        SET @msg = CONCAT(@errno, ': ', @msg);

        SET onError = TRUE;
    END;

    -- prepared statements
    PREPARE insert_error
    FROM
      'INSERT INTO error_log(person_id, logmessage) VALUES(?, ?)';

    PREPARE insert_change_log
    FROM
      'INSERT INTO t_change_log(person_id, person_role_id, action, logmessage) VALUES (?, ?, ?, ?)';

    PREPARE insert_person
    FROM
      'INSERT INTO t_person (fname, middlename, lname, suffix, precinct, ocvr_voter_id, assignment) VALUES (?, ?, ?, ?, ?, ?, ?)';
    
    PREPARE update_person
    FROM
      'UPDATE t_person SET precinct = ?, assignment = ? WHERE id = ?';

    PREPARE insert_person_role
    FROM
      'INSERT INTO t_person_role(person_id, role_id, certified_pcp, elected, term_start_date, term_end_date, inactive)
      VALUES(?, ?, ?, ?, ?, ?, ?)';
    
    PREPARE insert_address
    FROM 
      'INSERT INTO t_address (person_id, type, address, city, state, zip5, zip4) VALUES(?, ?, ?, ?, ?, ?, ?)';
    
    PREPARE update_address
    FROM
      'UPDATE t_address SET address = ?, city = ?, state = ?, zip5 = ?, zip4 = ? WHERE person_id = ? AND type = ?';

    OPEN c_upd;

    upd: LOOP
      SET @person_id = NULL;
      SET @prid = NULL;
      SET onError = FALSE;
      SET @msg = NULL;
      SET @elected = FALSE;

      FETCH c_upd INTO l_stg_id, l_member_id, l_fname, l_midname, l_lname, l_suffix, l_precinct, 
        l_voter_id, l_address, l_city, l_state, l_zip, l_assignment, 
        l_start_date, l_end_date, l_category; 
      /* FETCH c_upd INTO @stg_id, @member_id, @fname, @middlename, @lname, @suffix, @precinct, 
        @voter_id, @address, @city, @state, @zip, @assignment, @start_date, @end_date, @category; */
        IF done = TRUE THEN
            leave upd;
        END IF; 

      SET @err = NULL, @msg = NULL;
      SET @pcp_role = c_pcp_role;

      SET @stg_id = l_stg_id;
      SET @member_id = l_member_id;
      SET @fname = l_fname;
      SET @middlename = l_midname;
      SET @lname = l_lname;
      SET @suffix = l_suffix;
      SET @precinct = l_precinct;
      SET @voter_id = l_voter_id;
      SET @address = l_address;
      SET @city = l_city;
      SET @state = l_state;
      SET @zip = l_zip;
      SET @assignment = l_assignment;

      IF l_category = c_removed
      THEN
        START TRANSACTION;
        CALL s_inactivate_member(@member_id, p_report_date, @err, @msg);
        IF @err IS FALSE
        THEN
            COMMIT;
            ITERATE upd;
        ELSE
            ROLLBACK;
            SET @msg = CONCAT(c_removed, ': ', @msg);
            EXECUTE insert_error USING @member_id, @msg;
            ITERATE upd;
        END IF;
      END IF;

      IF @category = c_new
      OR @category = c_returning
      THEN
        START TRANSACTION;
        CALL s_pcp_add_new(@member_id, @fname, @middlename, @lname, @suffix, @precinct, @voter_id, 
              @address, @city, @state, @zip,  @assignment, @start_date, @end_date, @err, @msg);
        IF @err IS FALSE
        THEN
            COMMIT;
            ITERATE upd;
        ELSE
            ROLLBACK;
            SET @msg = CONCAT_WS(' ', @category, ':', @msg);
            EXECUTE insert_error USING @member_id, @msg;
            ITERATE upd;
        END IF;
      END IF;  -- c_new/c_returning

      /* Assumption is that precinct and address will almost always come together.
      ** However there are rare scenarios where one or the other could be independent
      ** of the other. For example, a member moves within their precinct would cause an
      ** address change but not a precinct change. */
      -- need precinct change
      IF INSTR(@category, c_precinct) > 0
      THEN
        START TRANSACTION;
        CALL s_pcp_precinct_change(@member_id, @fname, @middlename, @lname, @precinct, @assignment, @start_date, 
        @end_date, p_report_date, @err, @msg) ;
        IF @err IS FALSE
        THEN
            COMMIT;
            ITERATE upd;
        ELSE
            ROLLBACK;
            SET @msg = CONCAT_WS(' ', c_precinct, ':', @msg);
            EXECUTE insert_error USING @member_id, @msg;
            ITERATE upd;
        END IF;
      END IF;
      -- need address change
      IF INSTR(@category, c_address) > 0
      THEN
        START TRANSACTION;
        CALL s_address_upd_add(@member_id, @address_type, @address, @city, @state, @zip, @err, @msg) ;
        IF @err IS FALSE
        THEN
            COMMIT;
            ITERATE upd;
        ELSE
            ROLLBACK;
            SET @msg = CONCAT_WS(' ', c_address, ':', @msg);
            EXECUTE insert_error USING @member_id, @msg;
            ITERATE upd;
        END IF;
      END IF;

    END LOOP; -- upd

    CLOSE c_upd;

    -- deallocate prepared statements
    DEALLOCATE PREPARE insert_error;
    DEALLOCATE PREPARE insert_change_log;
    DEALLOCATE PREPARE insert_person;
    DEALLOCATE PREPARE update_person;
    DEALLOCATE PREPARE insert_person_role;
    DEALLOCATE PREPARE insert_address;
    DEALLOCATE PREPARE update_address;
END //


DELIMITER ;