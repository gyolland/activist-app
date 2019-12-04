DROP PROCEDURE IF EXISTS p_harmonize_names;

DELIMITER //

CREATE PROCEDURE p_harmonize_names (p_report_desc VARCHAR(40)) 
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE onError INT DEFAULT FALSE;
    DECLARE changed BOOLEAN DEFAULT FALSE;

    DECLARE l_member_id     INT         DEFAULT NULL;
    DECLARE l_fname, l_middlename, l_lname VARCHAR(40) DEFAULT NULL;

    DECLARE c_harmonize CURSOR FOR
        SELECT
          member_id
        , ifnull(e.fname, m.fname) as fname
        , ifnull(e.middlename, m.middlename) as middlename
        , replace( ifnull(e.lname, m.lname) , 'Mc ', 'Mc') as lname
        FROM member_stage m 
        JOIN t_person p ON m.member_id = p.id
        LEFT JOIN exception e ON m.member_id = e.person_id
        WHERE ( ifnull(m.fname, '') <> ifnull(p.fname, '')
        OR ifnull(m.middlename, '') <> ifnull(p.middlename, '') 
        OR ifnull(m.lname, '') <> ifnull(p.lname, ''));

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
        
    PREPARE up_p_fname FROM 'update t_person set fname = ? where id = ?';

    PREPARE up_p_middlename FROM 'update t_person set middlename = ? where id = ?';

    PREPARE up_p_lname FROM 'update t_person set lname = ? where id = ?';

    OPEN c_harmonize;

    harmonize: LOOP
        SET onError = FALSE;
        SET changed = FALSE;

        SET @member_id = NULL;
        SET @fname = NULL;
        SET @middlename = NULL;
        SET @lname = NULL;

        FETCH c_harmonize INTO l_member_id, l_fname, l_middlename, l_lname;
            IF done = TRUE THEN
                leave harmonize;
            END IF;
        
        SELECT fname, middlename, lname
        INTO @fname, @middlename, @lname 
        FROM t_person
        WHERE id = l_member_id;

        -- prepare log message
        SET @pid = l_member_id;
        SET @prid = NULL;
        SET @action = 'HARMONIZE NAME';
        SET @msg = CONCAT_WS(' ', 'Harmonized name to', l_fname, l_middlename, l_lname, 'from', @fname, @middlename, @lname, '; source', p_report_desc);

        IF onError = TRUE THEN
            ITERATE harmonize;
        END IF;

        START TRANSACTION;
        
        SET @member_id = l_member_id;

        IF  IFNULL(@fname, '') <> IFNULL(l_fname, '')
        THEN
            SET @fname = l_fname;
            EXECUTE up_p_fname USING @fname, @member_id;
            SET changed = TRUE;
        END IF;

        IF IFNULL(@middlename, '') <> IFNULL(l_middlename, '')
        THEN
            SET @middlename = l_middlename;
            EXECUTE up_p_middlename USING @middlename, @member_id;
            SET changed = TRUE;
        END IF;

        IF IFNULL(@lname, '') <> IFNULL(l_lname, '')
        THEN
            SET @lname = l_lname;
            EXECUTE up_p_lname USING @lname, @member_id;
            SET changed = TRUE;
        END IF;

        IF changed = TRUE THEN
            EXECUTE insert_change_log USING @pid, @prid, @action, @msg;
        END IF;

        IF onError = TRUE THEN
            ITERATE harmonize;
        END IF;

        COMMIT;
    END LOOP; -- harmonize

    CLOSE c_harmonize;

    -- deallocate prepared statements
    DEALLOCATE PREPARE up_p_fname;
    DEALLOCATE PREPARE up_p_middlename;
    DEALLOCATE PREPARE up_p_lname;
END //

DELIMITER ;