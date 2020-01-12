DROP PROCEDURE IF EXISTS s_pcp_add_new;
/* Prodedure: s_pcp_add_new - and single new pcp. Built as a subroutine to be used by other procedures

*/
DELIMITER //

CREATE PROCEDURE s_pcp_add_new(IN p_person_id INT, IN p_fname VARCHAR(40), IN p_middlename VARCHAR(40),
    IN p_lname VARCHAR(40), p_suffix VARCHAR(10), IN p_precinct INT, IN p_voter_id VARCHAR(14),
    IN p_address VARCHAR(100), IN p_city VARCHAR(40), IN p_state char(2), IN p_zip VARCHAR(15),
    IN p_assignment VARCHAR(40), IN p_start_date DATE, IN p_end_date DATE, 
    OUT o_error BOOLEAN, OUT o_message TEXT)
BEGIN
    DECLARE onError INT DEFAULT FALSE;

    DECLARE c_pcp_role INT DEFAULT 3;
    DECLARE c_elected VARCHAR(40) DEFAULT 'Elected';

    -- condition/exception handlers
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET @errno = NULL;

    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        GET CURRENT DIAGNOSTICS CONDITION 1
        @errno = MYSQL_ERRNO, @msg = MESSAGE_TEXT;

        SET @msg = CONCAT_WS(' ', @errno, ':', @msg);
        SET o_message = CONCAT_WS(' ', 'PROC: p_pcp_add_new', CONCAT('Member ID: ', p_person_id), @msg );
        SET o_error = TRUE;
    END;

    -- prepared statements
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
    

    SET o_error     = FALSE;
    SET o_message   = NULL;
    SET onError     = FALSE;

    body:
    BEGIN
        SET @member_id  = p_person_id;
        SET @fname      = p_fname;
        SET @middlename = p_middlename;
        SET @lname      = p_lname;
        SET @suffix     = p_suffix;
        SET @precinct   = p_precinct;
        SET @assignment = p_assignment;
        SET @start_date = p_start_date;
        SET @end_date   = p_end_date;
        SET @address    = p_address;
        SET @city       = p_city;
        SET @state      = p_state;
        SET @zip        = p_zip;

        IF INSTR(@assignment, c_elected) > 0
        THEN
            SET @elected = TRUE;
        ELSE
            SET @elected = FALSE;
        END IF;

        SET @pcp_role_id = c_pcp_role;
        SET @certified = TRUE;
        SET @inactive = FALSE;
        SET @address_type = 'RESI'; -- currently only saving residential address

        IF @member_id IS NULL
        THEN
            -- null member id insert t_person
            EXECUTE insert_person USING @fname, @middlename, @lname, @suffix, @precinct, @voter_id, @assignment;
            --  capture t_person id
            SET @member_id = LAST_INSERT_ID();
        ELSE
            -- has member id, update t_person
            EXECUTE update_person USING @precinct, @assignment, @member_id;
        END IF;
        IF onError = TRUE
        THEN
            LEAVE body;
        END IF;

        -- add person role record
        EXECUTE insert_person_role USING @member_id, @pcp_role_id, @certified, @elected, @start_date, @end_date, @inactive;
        SET @person_role_id = LAST_INSERT_ID();
        IF onError = TRUE
        THEN
            LEAVE body;
        END IF;

        -- add/update address
        CALL p_address_upd_add(@member_id, @address_type, @address, @city, @state, @zip, @err, @msg);

        IF @err = TRUE
        THEN
            SET @msg = CONCAT_WS(' ', c_new, ':', @msg);
            EXECUTE insert_error USING @member_id, @msg;
            LEAVE body;
        END IF;

        SET @action = 'ADDED';
        SET @msg = CONCAT_WS(' ', @fname, @middlename, @lname);
        EXECUTE insert_change_log USING @member_id, @person_role_id, @action, @msg;
    END body;

    DEALLOCATE PREPARE insert_error;
    DEALLOCATE PREPARE insert_change_log;
    DEALLOCATE PREPARE insert_person;
    DEALLOCATE PREPARE update_person;
    DEALLOCATE PREPARE insert_person_role;
END //

DELIMITER ;

