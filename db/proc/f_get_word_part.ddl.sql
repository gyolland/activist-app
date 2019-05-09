DROP FUNCTION IF EXISTS f_get_word_part;

DELIMITER $$
/********************************************************************************
Example name: Dr. Jane Janet Jingleheimer Schmidt, Esq.
Names will come in lots of forms. The most will either be FirstName LastName or 
First Middle Last. This is an attempt to extract identified piece of any string
separate by spaces. For practicality, the maximun number of words supported will
be limited to 10 words.
********************************************************************************/

CREATE FUNCTION f_get_word_part (p_word_str VARCHAR(100), p_part_no INT)
RETURNS VARCHAR(40)
DETERMINISTIC
BEGIN
    DECLARE l_word_part VARCHAR(40);
    DECLARE l_string VARCHAR(100);
    DECLARE Xi INT DEFAULT 0;
    DECLARE l_pos INT DEFAULT 0;

    -- trim leading spaces and
    -- ensure there is at least 1 space on the end
    SET l_string = TRIM(p_word_str);

    -- incase a single word with no leading or trailing spaces
    -- only when p_part_no = 1, all other cases should return null
    IF p_part_no = 1 THEN
        SET l_word_part = l_string;
    END IF;

    -- eliminate multiple continuous spaces
    WHILE INSTR(l_string, '  ') > 0  DO
        SET l_string = REPLACE(l_string, '  ', ' ');
    END WHILE;

    WHILE INSTR(l_string, ' ') > 0 DO
        SET l_pos = INSTR(l_string, ' ');  -- 'John Jakob Jingle Jimer'
        SET l_word_part = TRIM(LEFT(l_string, l_pos));
        SET l_string = CONCAT(TRIM(SUBSTR(l_string, l_pos, 100)), ' ');

        SET Xi = Xi + 1;
        IF Xi >= p_part_no THEN
            SET l_string = '';
        END IF;
    END WHILE;

    SET l_word_part = REPLACE(l_word_part, ',', '');
    SET l_word_part = REPLACE(l_word_part, '.', '');

    IF NOT LENGTH(l_word_part) > 0 THEN
        SET l_word_part = NULL;
    END IF;

RETURN l_word_part;
END $$

DELIMITER ;
