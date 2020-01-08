DROP PROCEDURE IF EXISTS p_address_exists;
/* Procedure: p_address_exists - test to see if address exists in t_address given a person_id and address type
** input: p_person_id type int, p_address_type type varchar(4)
** output: o_found type boolean, o_error type boolean, o_message type text
** selects from t_address using person_id and address type. If the record is found return o_found = true else false
** o_error and o_message are used to return error conditions other than NOT FOUND
*/
DELIMITER //

CREATE PROCEDURE p_address_exists(IN p_person_id INT, IN p_address_type VARCHAR(4), 
    OUT o_found BOOLEAN, OUT o_error BOOLEAN, OUT o_message TEXT)
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE onError INT DEFAULT FALSE;

    DECLARE l_address VARCHAR(100) DEFAULT NULL;

    -- condition/exception handlers
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET @errno = NULL;

    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        GET CURRENT DIAGNOSTICS CONDITION 1
            @errno = MYSQL_ERRNO, @msg = MESSAGE_TEXT;

        SET o_message = CONCAT(@errno, ': ', @msg);

        SET o_error = TRUE;
    END;

    SET o_found = FALSE;

    SELECT address
      INTO l_address
      FROM t_address
     WHERE person_id = p_person_id
       AND type = p_address_type;

    -- GET CURRENT DIAGNOSTICS CONDITION 1
    -- @errno = MYSQL_ERRNO, @msg = MESSAGE_TEXT;

    IF @errno IS NULL -- not found set in exception handler above
    THEN
        SET o_error = FALSE;
        SET o_message = NULL;

        IF l_address IS NOT NULL
        THEN
            SET o_found = TRUE;
        END IF;
    END IF;
END //

DELIMITER ;