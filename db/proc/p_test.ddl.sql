DROP PROCEDURE IF EXISTS p_test;

DELIMITER //

CREATE PROCEDURE p_test (IN p_person_id INT, IN p_report_date DATE, OUT o_error BOOLEAN, OUT o_message TEXT)
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE onError INT DEFAULT FALSE;

    DECLARE v_person_id         INT         DEFAULT NULL;
    DECLARE v_inactive          BOOLEAN     DEFAULT FALSE;
    DECLARE v_person_role_id    INT         DEFAULT NULL;

    DECLARE c_pcp_role_id       INT         DEFAULT 3;
    DECLARE c_inactive_true     BOOLEAN     DEFAULT TRUE;
    DECLARE c_inactive_false    BOOLEAN     DEFAULT FALSE;

    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        GET CURRENT DIAGNOSTICS CONDITION 1
            @errno = MYSQL_ERRNO, @msg = MESSAGE_TEXT;

        SET o_message = CONCAT(@errno, ': ', @msg);

        SET o_error = TRUE;
    END;

    PREPARE inactivate_person_role
    FROM -- WARNING id is t_person_role.id NOT t_person_role.person_id.
      'UPDATE t_person_role SET term_end_date = ?, inactive = TRUE WHERE id = ?'; 

    SET @end_date = p_report_date;

    SELECT id 
      INTO @person_role_id
      FROM t_person_role
     WHERE person_id = p_person_id
       AND role_id   = c_pcp_role_id
       AND inactive  = c_inactive_false;
    
    GET CURRENT DIAGNOSTICS CONDITION 1
    @errno = MYSQL_ERRNO, @msg = MESSAGE_TEXT;

    IF @errno IS NULL
    THEN
        EXECUTE inactivate_person_role USING @end_date, @person_role_id;
        SET o_error = FALSE;
        SET o_message = NULL;
    ELSE
        SET o_error = TRUE;
        SET o_message = CONCAT(@errno, ': ', @msg);
    END IF;
END //

DELIMITER ;
