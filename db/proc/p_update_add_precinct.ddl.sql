DROP PROCEDURE IF EXISTS p_update_add_precinct;

DELIMITER //

CREATE PROCEDURE p_update_add_precinct (p_term_end_date DATE, p_date_of_report DATE)
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE onError INT DEFAULT FALSE;

    -- fields for cursor
    DECLARE person_id INT(11);
    DECLARE ocvr_voter_id VARCHAR(12);
    DECLARE assignment VARCHAR(40);
    DECLARE precinct INT DEFAULT NULL;
    DECLARE r_address, m_address VARCHAR(100);
    DECLARE r_city, m_city VARCHAR(40);
    DECLARE r_zip, m_zip VARCHAR(15);
    DECLARE r_state, m_state VARCHAR(2);
    DECLARE precinct_change, address_change varchar(1);

    -- selection of columns needed for update
    DECLARE c_pcp CURSOR FOR 
    SELECT p.id AS person_id
         , p.ocvr_voter_id
         , CASE WHEN p.precinct <> o.precinct THEN 'X' ELSE null END AS precinct_change
         , CASE WHEN a.address <> o.r_address THEN 'X' ELSE null END AS address_change
         , o.precinct
         , o.r_address
         , o.r_city
         , o.r_state
         , o.r_zip
         , o.m_address
         , o.m_city
         , o.m_state
         , o.m_zip
         , o.assignment
       FROM t_person p 
       JOIN t_person_role r0 ON p.id = r0.person_id
       JOIN t_import_ocvr_tmp o USING(ocvr_voter_id)
       JOIN t_address a ON p.id = a.person_id
      WHERE r0.role_id = 3 
        AND r0.inactive = FALSE
        AND a.type = 'RESI' ;

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
    PREPARE update_address
    FROM
        'UPDATE t_address SET address = ?, city = ?, state = ?, zip5 = ?, zip4 = ? WHERE person_id = ? AND type = ?';

    PREPARE update_precinct
    FROM
        'UPDATE t_person SET precinct = ?, assignment = ? WHERE id = ?';

    PREPARE inactivate_person_role
    FROM
        'UPDATE t_person_role SET term_end_date = ?, inactive = TRUE WHERE person_id = ? AND role_id = 3 AND inactive = FALSE';

    PREPARE insert_person_role
    FROM
        'INSERT INTO t_person_role(person_id, role_id, certified_pcp, elected, term_start_date, term_end_date, inactive)
        VALUES(?, ?, ?, ?, ?, ?, ?)';

    PREPARE insert_change_log
    FROM
        'INSERT INTO t_change_log(person_id, person_role_id, action, logmessage) VALUES (?, ?, ?, ?)';

    SET @_term_end = p_term_end_date;
    SET @report_date = p_date_of_report;

    OPEN c_pcp;

        -- DEBUG
        -- SET @_msg = concat('Before loop. Done: ', done);
        -- SET @_pid = '000';
        -- SET @_prid = '000';
        -- EXECUTE insert_change_log USING @_pid, @_prid, @_act, @_msg;

    pcploop: LOOP
        SET onError = FALSE;
        SET @_prid = NULL;

        -- DEBUG
        -- SET @_msg = concat('Before Fetch. Done: ', done);
        -- SET @_pid = '000';
        -- SET @_prid = '000';
        -- EXECUTE insert_change_log USING @_pid, @_prid, @_act, @_msg;

        FETCH  c_pcp INTO person_id, ocvr_voter_id, precinct_change, address_change, precinct, r_address, 
                          r_city, r_state, r_zip, m_address, m_city, m_state, m_zip, assignment;

        -- DEBUG
        -- SET @_msg = concat('After Fetch. address: ', ifnull(address_change,'o'), ' precinct: ', ifnull(precinct_change,'o'), ' Done: ', done);
        -- SET @_pid = '000';
        -- SET @_prid = '000';
        -- EXECUTE insert_change_log USING @_pid, @_prid, @_act, @_msg;

        IF address_change <> 'X' AND precinct_change <> 'X' THEN
            -- DEBUG
            -- SET @_msg = concat('No Match, iterate. Done: ', done);
            -- SET @_pid = '000';
            -- SET @_prid = '000';
            -- EXECUTE insert_change_log USING @_pid, @_prid, @_act, @_msg;

            ITERATE pcploop;
        END IF;

        IF done = TRUE THEN
            -- DEBUG
            -- SET @_msg = concat('Done Check. Done: ', done);
            -- SET @_pid = '000';
            -- SET @_prid = '000';
            -- EXECUTE insert_change_log USING @_pid, @_prid, @_act, @_msg;

            leave pcploop;
        END IF;

        SET @_pid = person_id;

        START TRANSACTION;

        IF address_change = 'X' THEN
            SET @add_type = 'RESI';
            SET @_address = TRIM(r_address);
            SET @_city = TRIM(r_city);
            SET @state = TRIM(r_state);
            SET @_zip5 = LEFT(TRIM(r_zip), 5);
            SET @_zip4 = CASE WHEN LENGTH(TRIM(r_zip)) > 5 THEN RIGHT(TRIM(r_zip), 4) ELSE NULL END;
            EXECUTE update_address USING @_address, @_city, @state, @_zip5, @_zip4, @_pid, @add_type ;

            IF onError = TRUE THEN
                ITERATE pcploop;
            END IF;

            IF LENGTH(TRIM(m_address)) > 0 THEN
                -- mailing
                SET @add_type = 'MAIL';
                SET @_address = TRIM(m_address);
                SET @_city = TRIM(m_city);
                SET @state = TRIM(m_state);
                SET @_zip5 = LEFT(TRIM(m_zip), 5);
                SET @_zip4 = CASE WHEN LENGTH(TRIM(m_zip)) > 5 THEN RIGHT(TRIM(m_zip), 4) ELSE NULL END;
                EXECUTE update_address USING @_address, @_city, @state, @_zip5, @_zip4, @_pid, @add_type ;
            END IF;

            IF onError = TRUE THEN
                ITERATE pcploop;
            END IF;
        END IF;

        IF precinct_change = 'X' THEN
            SET @_assignment = TRIM(assignment);

            -- add t_person_role records
            IF INSTR(@_assignment, 'elect') > 0 THEN
                SET @_elected = TRUE;
            ELSE 
                SET @_elected = FALSE;
            END IF;

            SET @_term_start = f_get_assignment_date(@_assignment);
            SET @_old_term_end = date_sub(@_term_start, INTERVAL 1 DAY);
            SET @_new_term_end = p_term_end_date;
    
            -- update t_person
            EXECUTE update_precinct USING @_precinct, @_assignment, @_pid;

            -- update old t_person_record, set term_end_date, make inactive
            EXECUTE inactivate_person_role USING @_old_term_end, @_pid;

            -- insert new t_person_role record.
            -- person_id, role_id, certified_pcp, elected, term_start_date, term_end_date, inactive
            SET @role = 3;
            SET @cert = TRUE;
            SET @inact = FALSE;
            EXECUTE insert_person_role USING @_pid, @role, @cert, @_elected, @_term_start, @_new_term_end, @inact;

            -- capture t_person_role_id
            SET @_prid = LAST_INSERT_ID();

            IF onError = TRUE THEN
                ITERATE pcploop;
            END IF;
        END IF;

        IF address_change = 'X' OR precinct_change = 'X' THEN
            -- person_id, person_role_id, action, logmessage
            SET @_act = 'ADDRESS/PRECINCT';
            SET @_msg = CONCAT('PCP added with report date: ', @report_date);
            EXECUTE insert_change_log USING @_pid, @_prid, @_act, @_msg;

            COMMIT;
        END IF;

    END LOOP; -- pcploop

    CLOSE c_pcp;

    -- deallocate prepared statements
    DEALLOCATE PREPARE update_address;
    DEALLOCATE PREPARE update_precinct;
    DEALLOCATE PREPARE inactivate_person_role;
    DEALLOCATE PREPARE insert_person_role;
    DEALLOCATE PREPARE insert_change_log;
END //

DELIMITER ;    