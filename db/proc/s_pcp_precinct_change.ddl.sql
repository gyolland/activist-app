DROP PROCEDURE IF EXISTS s_pcp_precinct_change;
/* Prodedure: s_pcp_precinct_change - Update single pcp changing precinct, assignment and role data.
** Precinct and assignment data are updated in the t_person record while the t_person_role record gets 
** inactivated and a new one added with current data. Address data is handle by another procedure.
** Built as a subroutine to be used by other procedures
*/
DELIMITER //

CREATE PROCEDURE s_pcp_precinct_change(IN p_person_id INT, IN p_fname VARCHAR(40), IN p_middlename VARCHAR(40),
    IN p_lname VARCHAR(40), IN p_precinct INT, IN p_assignment VARCHAR(40), IN p_start_date DATE, 
    IN p_end_date DATE, IN p_report_date DATE, OUT o_error BOOLEAN, OUT o_message TEXT)
BEGIN
    DECLARE onError             INT DEFAULT FALSE;

    DECLARE c_pcp_role          INT DEFAULT 3;
    DECLARE c_elected           VARCHAR(40) DEFAULT 'Elected';
    DECLARE c_action            VARCHAR(20) DEFAULT 'PRECINCT';
    DECLARE c_pcp_role_id       INT DEFAULT 3;
    DECLARE c_inactive_false    BOOLEAN DEFAULT FALSE;
    DECLARE c_inactive_true     BOOLEAN DEFAULT TRUE;

    -- condition/exception handlers
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET @errno = NULL;

    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        GET CURRENT DIAGNOSTICS CONDITION 1
        @errno = MYSQL_ERRNO, @msg = MESSAGE_TEXT;

        SET @msg = CONCAT_WS(' ', @errno, ':', @msg);
        SET o_message = CONCAT_WS(' ', 'PROC: s_pcp_precinct_change', CONCAT('Member ID: ', p_person_id), @msg );
        SET o_error = TRUE;
    END;

    -- prepared statements
    PREPARE insert_change_log
    FROM
      'INSERT INTO t_change_log(person_id, person_role_id, action, logmessage) VALUES (?, ?, ?, ?)';
    
    PREPARE update_person
    FROM
      'UPDATE t_person SET precinct = ?, assignment = ? WHERE id = ?';

    PREPARE insert_person_role
    FROM
      'INSERT INTO t_person_role(person_id, role_id, certified_pcp, elected, term_start_date, term_end_date, inactive)
      VALUES(?, ?, ?, ?, ?, ?, ?)';

    PREPARE inactivate_person_role
    FROM -- WARNING id is t_person_role.id NOT t_person_role.person_id.
      'UPDATE t_person_role SET term_end_date = ?, inactive = TRUE WHERE id = ?'; 
    
    SET @report_date    = p_report_date;
    SET @start_date     = p_start_date;
    SET @end_date       = p_end_date;
    SET @term_end_date = ADDDATE(@start_date, -1);

    SET @member_id      = p_person_id;
    SET @precinct       = p_precinct;
    SET @assignment     = p_assignment;
    SET @action         = c_action;
    SET @role_id        = c_pcp_role_id;
    SET @certified      = TRUE;
    SET @elected        = CASE WHEN INSTR(@assignment, c_elected) > 0 THEN TRUE ELSE FALSE END;
    SET @inactive       = c_inactive_false;

    SET o_error         = FALSE;
    SET o_message       = NULL;

    body:
    BEGIN
        SELECT id 
        INTO @person_role_id
        FROM t_person_role
        WHERE person_id = @member_id
        AND role_id   = c_pcp_role_id
        AND inactive  = c_inactive_false;

        GET CURRENT DIAGNOSTICS CONDITION 1
        @errno = MYSQL_ERRNO, @msg = MESSAGE_TEXT;

        IF @errno <> FALSE
        THEN
            -- maybe report error: Role record not found
            SET @msg        = CONCAT_WS(' ', 'MEMBER_ID:', @member_id, '|', 'No active person role record found');
            SET o_error     = TRUE;
            SET o_message   = CONCAT_WS(' ', 'PROC: s_pcp_precinct_change', @msg);
            LEAVE body;
        END IF;

        EXECUTE update_person USING @precinct, @assignment, @member_id;
        IF onError = TRUE
        THEN
            LEAVE body;
        END IF;

        EXECUTE inactivate_person_role USING @term_end_date, @person_role_id;
        IF onError = TRUE
        THEN
            LEAVE body;
        END IF;

        EXECUTE insert_person_role USING @member_id, @role_id, @certified, @elected, @start_date, @end_date, @inactive;
        IF onError = TRUE
        THEN
            LEAVE body;
        END IF;

        -- address will be updated by a separate procedure
    END body;

    DEALLOCATE PREPARE insert_change_log;
    DEALLOCATE PREPARE update_person;
    DEALLOCATE PREPARE insert_person_role;
    DEALLOCATE PREPARE inactivate_person_role;
END // -- s_pcp_precinct_change

DELIMITER ;
