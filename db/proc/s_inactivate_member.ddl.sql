DROP PROCEDURE IF EXISTS s_inactivate_member;

DELIMITER //

CREATE PROCEDURE s_inactivate_member(IN p_person_id INT, IN p_report_date DATE, OUT o_error BOOLEAN, OUT o_message TEXT)
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE onError INT DEFAULT FALSE;

    DECLARE c_pcp_role_id       INT         DEFAULT 3;
    DECLARE c_inactive_false    BOOLEAN     DEFAULT FALSE;
    DECLARE c_action            VARCHAR(20) DEFAULT 'REMOVED';

    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        GET CURRENT DIAGNOSTICS CONDITION 1
            @errno = MYSQL_ERRNO, @msg = MESSAGE_TEXT;

        SET o_message = CONCAT(@errno, ': ', @msg);

        SET o_error = TRUE;
    END;

    -- prepared statements
    PREPARE inactivate_person_role
    FROM -- WARNING id is t_person_role.id NOT t_person_role.person_id.
      'UPDATE t_person_role SET term_end_date = ?, inactive = TRUE WHERE id = ?';

    SET o_error = FALSE;
    SET o_message = NULL;
    SET @errno = FALSE;
    SET @msg = NULL;
    SET @person_role_id = NULL;

    SET @end_date = p_report_date;
    SET @person_id = p_person_id;
    SET @action = c_action;

    SELECT id
      INTO @person_role_id
      FROM t_person_role
     WHERE person_id = @person_id
       AND role_id   = c_pcp_role_id
       AND inactive  = c_inactive_false;

    GET CURRENT DIAGNOSTICS CONDITION 1
    @errno = MYSQL_ERRNO, @msg = MESSAGE_TEXT;

    IF @errno IS FALSE
    THEN
        SELECT CONCAT_WS(' ', precinct, '|', fname, middlename, lname)
          INTO @logmsg
          FROM t_person
         WHERE id = @person_id;

        EXECUTE inactivate_person_role USING @end_date, @person_role_id;
        EXECUTE insert_change_log USING @person_id, @person_role_id, @action, @logmsg;
    ELSE
        SET o_error = TRUE;
        SET o_message = CONCAT(@errno, ': ', @msg);
    END IF;

    DEALLOCATE PREPARE inactivate_person_role;
END //

DELIMITER ;