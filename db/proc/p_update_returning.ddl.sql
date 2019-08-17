DROP PROCEDURE IF EXISTS p_update_returning;

DELIMITER //

CREATE PROCEDURE p_update_returning (p_term_end_date DATE, p_date_of_report DATE)
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE onError INT DEFAULT FALSE;

-- fields for cursor
    DECLARE person_id INT(11);
    DECLARE ocvr_voter_id VARCHAR(12);
    DECLARE assignment VARCHAR(40);

-- select PCPs that had previously been elected/appointed but term ended.
DECLARE c_returning CURSOR FOR 
SELECT p.id AS person_id, p.ocvr_voter_id, o.assignment
  FROM t_person p
  JOIN t_import_ocvr_tmp o USING (ocvr_voter_id)
  JOIN ( SELECT * FROM t_person_role WHERE inactive = TRUE AND role_id = 3 AND term_end_date < now() ) r00 ON p.id = r00.person_id
 WHERE NOT EXISTS (SELECT 'X' FROM t_person_role t0 WHERE p.id = t0.person_id AND t0.inactive = FALSE AND t0.role_id = 3)  ;

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
    PREPARE insert_person_role
    FROM
        'INSERT INTO t_person_role(person_id, role_id, certified_pcp, elected, term_start_date, term_end_date, inactive)
        VALUES(?, ?, ?, ?, ?, ?, ?)';

    PREPARE insert_change_log
    FROM
        'INSERT INTO t_change_log(person_id, person_role_id, action, logmessage) VALUES (?, ?, ?, ?)';

    SET @_term_end = p_term_end_date;
    SET @report_date = p_date_of_report;

    OPEN c_returning;

    addpcp: LOOP
        SET onError = FALSE;

        FETCH  c_returning INTO person_id, ocvr_voter_id, assignment;
        IF done = TRUE THEN
            leave addpcp;
        END IF;    

        SET @_assignment = TRIM(assignment);

        START TRANSACTION; 

        -- add t_person_role records
        IF INSTR(@_assignment, 'elect') > 0 THEN
            SET @_elected = TRUE;
        ELSE 
            SET @_elected = FALSE;
        END IF;

        SET @_term_start = f_get_assignment_date(@_assignment);

        -- person_id, role_id, certified_pcp, elected, term_start_date, term_end_date, inactive
        SET @_pid = person_id;
        SET @role = 3;
        SET @cert = TRUE;
        SET @inact = FALSE;
        EXECUTE insert_person_role USING @_pid, @role, @cert, @_elected, @_term_start, @_term_end, @inact;

        IF onError = TRUE THEN
            ITERATE addpcp;
        END IF;

        -- capture t_person_role_id
        SET @_prid = LAST_INSERT_ID();

-- person_id, person_role_id, action, logmessage
        SET @_act = 'RETURNING';
        SET @_msg = CONCAT('PCP returning with report date: ', @report_date);
        EXECUTE insert_change_log USING @_pid, @_prid, @_act, @_msg;

        COMMIT;
    END LOOP; -- addpcp

    CLOSE c_returning;

    -- deallocate prepared statements
    DEALLOCATE PREPARE insert_person_role;
    DEALLOCATE PREPARE insert_change_log;
END //

DELIMITER ;
