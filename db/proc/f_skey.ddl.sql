DROP FUNCTION IF EXISTS f_skey;

DELIMITER $$
/********************************************************************************
f_skey: build surrogate key from provided strings. Intended to build a sudo key
        based on a persons name removing space and punctuation characters.
  Max length 120 characters.
  Example name: Garret Augustus Hobart becomes GarretAugustusHobart
  Example name: Eugene Gladstone O'Neill becomes EugeneGladstoneONeill
********************************************************************************/

CREATE FUNCTION f_skey(p_str1 VARCHAR(40), p_str2 VARCHAR(40), p_str3 VARCHAR(40))
RETURNS VARCHAR(120)
DETERMINISTIC
BEGIN
    DECLARE l_string VARCHAR(120);
    DECLARE l_str1 VARCHAR(40);
    DECLARE l_str2 VARCHAR(40);
    DECLARE l_str3 VARCHAR(40);

    -- check if string1 is null
    IF ISNULL(p_str1) THEN
       SET l_str1 = '';
    ELSE
       SET l_str1 = TRIM(p_str1);
    END IF; 

    -- check if string2 is null
    IF ISNULL(p_str2) THEN
       SET l_str2 = '';
    ELSE
       SET l_str2 = TRIM(p_str2);
    END IF; 

    -- check if string3 is null
    IF ISNULL(p_str3) THEN
       SET l_str3 = '';
    ELSE
       SET l_str3 = TRIM(p_str3);
    END IF; 

    SET l_string = CONCAT(l_str1, l_str2, l_str3);

    -- remove spaces in string
    SET l_string = REPLACE(l_string, ' ', '');

    -- remove hyphens in string
    SET l_string = REPLACE(l_string, '-', '');

    -- remove single quotes in string
    SET l_string = REPLACE(l_string, '\'', '');

RETURN l_string;
END $$

DELIMITER ;
