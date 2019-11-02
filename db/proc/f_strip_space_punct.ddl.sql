DROP FUNCTION IF EXISTS f_strip_space_punct;

DELIMITER $$
/********************************************************************************
f_strip_space_punct: remove white space and punctuation marks from a string.
  Max length 200 characters.
  Example name: Dr. Jane Janet Jingleheimer Schmidt, Esq.
********************************************************************************/

CREATE FUNCTION f_strip_space_punct(p_string VARCHAR(200))
RETURNS VARCHAR(200)
DETERMINISTIC
BEGIN
    DECLARE l_string VARCHAR(200);

    -- check if string is null
    IF ISNULL(p_string) THEN
       SET l_string = p_string;
    ELSE
       SET l_string = REGEXP_REPLACE(p_string, '[[:SPACE:]]|[[:PUNCT:]]', '') ;
    END IF; 

RETURN l_string;
END $$

DELIMITER ;
