DROP PROCEDURE IF EXISTS p_remove_pcp;

DELIMITER $$

CREATE PROCEDURE p_remove_pcp (p_term_end_date DATE)
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_error INT DEFAULT '00000';
    DECLARE errno INT;
    DECLARE msg TEXT;
    DECLARE v_person_id INT;
    DECLARE v_action VARCHAR(20) DEFAULT 'REMOVED';
    DECLARE v_logmsg VARCHAR(255) DEFAULT 'PCP deactivated on report ';

    DECLARE c_pcp CURSOR FOR
        SELECT p.id
          FROM t_person p
          JOIN t_person_role r0 ON p.id = r0.person_id
          LEFT JOIN t_import_ocvr_tmp o USING(ocvr_voter_id)
         WHERE p.gender <> 'X'
           AND r0.role_id = 3
           AND r0.inactive = FALSE
           AND o.ocvr_voter_id IS NULL;

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

    deactivate: LOOP
        FETCH c_pcp INTO v_person_id;
        IF done = TRUE THEN
            leave deactivate;
        END IF;

        START TRANSACTION;
            INSERT INTO t_change_log(person_id, action, logmessage)
            VALUES (v_person_id, v_action, CONCAT(v_logmsg, p_term_end_date));

            UPDATE t_person_role SET term_end_date = p_term_end_date, inactive = TRUE 
            WHERE person_id = v_person_id 
              AND role_id = 3 -- PCP
              AND inactive = FALSE ;
              
        IF v_error = '00000' THEN
            COMMIT;
        END IF ;

        SET v_error = '00000';

    END LOOP; --  End deactivate loop

    CLOSE c_pcp;

END $$

DELIMITER ;
