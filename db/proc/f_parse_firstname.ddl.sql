CREATE DEFINER=`geo`@`%` FUNCTION `f_parse_firstname`(p_fullname VARCHAR(100)) RETURNS varchar(40) CHARSET latin1
BEGIN

  DECLARE l_firstname VARCHAR(40);
  DECLARE l_spaceposition INT;
  DECLARE l_fullname VARCHAR(100);
  
  SET l_fullname = TRIM(p_fullname);
  
  SET l_spaceposition = INSTR(TRIM(l_fullname), ' ');
  
  CASE WHEN l_spaceposition > 0 THEN
    SET l_firstname = TRIM(LEFT(l_fullname, l_spaceposition));
  ELSE
    SET l_firstname = l_fullname;
  END CASE;
  
  RETURN l_firstname;
END