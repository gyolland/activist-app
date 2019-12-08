DROP FUNCTION IF EXISTS f_cleanse_name;

DELIMITER $$
/********************************************************************************
f_cleanse_name: Some of the name data we receive has spaces in combination with 
other characters that should be removed to ensure comparisons of new & old versions
of names are more accurate. For example, some data sources put a space between
parts of some names, such that a name like 'McCoy' is spelled like 'Mc Coy' or
a hyphenated name will have a space following the hyphen.
********************************************************************************/

CREATE FUNCTION f_cleanse_name(p_name_str VARCHAR(40))
RETURNS VARCHAR(40)
DETERMINISTIC
BEGIN
    DECLARE l_name_str VARCHAR(40) DEFAULT NULL;
    DECLARE l_return VARCHAR(40) DEFAULT NULL;

    IF NOT ( ISNULL(p_name_str) OR p_name_str = '' ) -- empty string
    THEN
        SET l_name_str = TRIM(p_name_str);

        -- REPLACE is case sensitive
        SET l_name_str = REPLACE(l_name_str, 'MC ', 'MC');
        SET l_name_str = REPLACE(l_name_str, 'Mc ', 'Mc');
        SET l_name_str = REPLACE(l_name_str, '- ', '-');

        SET l_return = l_name_str;
    END IF;

    RETURN l_return;
END$$

DELIMITER ;