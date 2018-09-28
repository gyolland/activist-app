CREATE DEFINER=`geo`@`%` FUNCTION `f_parse_lastname`(p_fullname VARCHAR(100)) RETURNS varchar(40) CHARSET latin1
BEGIN

  DECLARE l_lastname VARCHAR(40);
  DECLARE l_fullname VARCHAR(100);
  DECLARE l_spaceposition INT;

  SET l_fullname = TRIM(p_fullname);
  SET l_spaceposition = INSTR(l_fullname, ' ');
  
  CASE WHEN l_spaceposition = 0 THEN
    SET l_lastname = NULL;
  ELSE
    SET l_lastname = TRIM(SUBSTR(l_fullname, l_spaceposition, 100));
  END CASE;
  
  -- check for space again to catch middle initial/name
  CASE WHEN l_lastname IS NOT NULL THEN
    SET l_spaceposition = INSTR(l_lastname, ' ');
    CASE WHEN l_spaceposition > 0 THEN
      SET l_lastname = TRIM(SUBSTR(l_lastname, l_spaceposition, 100));
	ELSE
      SET l_lastname = l_lastname;
	END CASE;
    ELSE
      SET l_lastname = NULL;
  END CASE;

RETURN l_lastname;
END