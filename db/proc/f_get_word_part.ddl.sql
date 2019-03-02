DROP FUNCTION IF EXISTS `f_get_word_part`;

DELIMITER $$
/********************************************************************************
Example name: Dr. Jane Janet Jingleheimer Schmidt, Esq.
Names will come in lots of forms. The most will either be FirstName LastName or 
First Middle Last. This is an attempt to extract identified piece of any string
separate by spaces. For practicality, the maximun number of words supported will
be limited to 10 words.
********************************************************************************/

CREATE FUNCTION `f_get_word_part` (p_word_str VARCHAR(100), p_part_no INT)
RETURNS VARCHAR(40)
BEGIN
    DECLARE l_word_part VARCHAR(40);
    DECLARE l_string VARCHAR(100);
    DECLARE Xi INT DEFAULT 0;
    DECLARE l_pos INT DEFAULT 0;

    -- trim leading spaces and
    -- ensure there is at least 1 space on the end
    SET l_string = CONCAT(LTRIM(p_word_str), ' ');

    WHILE Xi < p_part_no DO 
        SET l_pos = INSTR(l_string, ' ');
        SET l_word_part = TRIM(LEFT(l_string, l_pos));
        SET l_string = LTRIM(SUBSTR(l_string, l_pos, 100));

        IF LENGTH(TRIM(l_string)) > 0 THEN
            SET Xi = Xi + 1;
        ELSE
            SET Xi = p_part_no;
        END IF;
    END WHILE;

    SET l_word_part = REPLACE(l_word_part, ',', '');
    SET l_word_part = REPLACE(l_word_part, '.', '');

RETURN l_word_part;
END $$

DELIMITER ;