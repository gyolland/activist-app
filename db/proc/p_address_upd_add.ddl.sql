DROP PROCEDURE IF EXISTS p_address_upd_add;
/* Prodedure: p_address_upd_add - either update an address or insert an address depending on 
** whether the address already exists.
**  
*/
DELIMITER //

CREATE PROCEDURE p_address_upd_add(IN p_person_id INT, IN p_address_type VARCHAR(4), 
    IN p_address VARCHAR(100), IN p_city VARCHAR(40), p_state char(2), p_zip VARCHAR(15),
    OUT o_error BOOLEAN, OUT o_message TEXT)
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE onError INT DEFAULT FALSE;

    -- condition/exception handlers
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET @errno = NULL;

    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        GET CURRENT DIAGNOSTICS CONDITION 1
        @errno = MYSQL_ERRNO, @msg = MESSAGE_TEXT;

        SET @msg = CONCAT_WS(' ', @errno, ':', @msg);
        SET o_message = CONCAT_WS(' ', 'PROC: p_address_upd_add', CONCAT('Member ID: ', p_person_id), @msg );
        SET o_error = TRUE;
    END;

    -- prepared statements
    PREPARE insert_error
    FROM
      'INSERT INTO error_log(person_id, logmessage) VALUES(?, ?)';

    PREPARE insert_address
    FROM 
      'INSERT INTO t_address (person_id, type, address, city, state, zip5, zip4) VALUES(?, ?, ?, ?, ?, ?, ?)';
    
    PREPARE update_address
    FROM
      'UPDATE t_address SET address = ?, city = ?, state = ?, zip5 = ?, zip4 = ? WHERE person_id = ? AND type = ?';

    SET o_message   = NULL;
    SET o_error     = FALSE;

    body:
    BEGIN
        CALL p_address_exists(p_person_id, p_address_type, @found, @error, @message);

        IF @error = TRUE
        THEN
            SET o_error = TRUE;
            SET o_message = CONCAT_WS(' ', 'PROC: p_address_upd_add', CONCAT('Member ID: ', p_person_id), @message );
            LEAVE body;
        END IF;

        SET @member_id = p_person_id;
        SET @address_type = p_address_type;
        SET @address = p_address;
        SET @city = p_city;
        SET @state = UPPER(p_state);

        SET @zip = TRIM(p_zip);
        SET @zip5 = LEFT(@zip, 5);
        SET @zip4 = CASE WHEN LENGTH(@zip) > 5 THEN RIGHT(@zip, 4) ELSE NULL END;

        IF o_error = TRUE
        THEN
            LEAVE body;
        END IF;

        IF @found = TRUE
        THEN 
            EXECUTE update_address USING @address, @city, @state, @zip5, @zip4, @member_id, @address_type;
        ELSE
            EXECUTE insert_address USING @member_id, @address_type, @address, @city, @state, @zip5, @zip4;
        END IF;
    END body;

    DEALLOCATE PREPARE update_address;
    DEALLOCATE PREPARE insert_address;
END //

DELIMITER ;