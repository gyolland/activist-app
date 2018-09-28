CREATE DEFINER=`geo`@`%` FUNCTION `f_parse_middlename`(p_fullname VARCHAR(100)) RETURNS varchar(40) CHARSET latin1
BEGIN
  DECLARE l_middlename VARCHAR(40);
  DECLARE l_fullname VARCHAR(100);
  DECLARE l_spaceposition INT;
  
  SET l_fullname = TRIM(p_fullname);
  SET l_spaceposition = INSTR(l_fullname, ' ');
  
  CASE WHEN l_spaceposition > 0 THEN
    SET l_middlename = TRIM(SUBSTR(l_fullname, l_spaceposition, 100));
  ELSE
    SET l_middlename = NULL;
  END CASE;

  -- check see if there is actuall a middlename, set to null if no space found
  SET l_spaceposition = INSTR(l_middlename, ' ');
  
  CASE WHEN l_spaceposition > 0 THEN
    SET l_middlename = TRIM(SUBSTR(l_middlename, 1, l_spaceposition));
  ELSE
    SET l_middlename = NULL;
  END CASE;

RETURN l_middlename;
END