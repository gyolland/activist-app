DROP FUNCTION IF EXISTS `f_get_assignment_date`;

DELIMITER $$

CREATE FUNCTION `f_get_assignment_date` (p_assignment VARCHAR(100))
RETURNS DATE
BEGIN
     -- assignment looks like: Appointed 12/14/2018 
     -- or Elected 6/8/2018 
     -- or Elected 6/8/2018( Write-In)
     -- or Elected 6/8/2018 - changed precinct, in
	DECLARE l_date_string VARCHAR(10);
     DECLARE l_assignment_date DATE DEFAULT NULL;
     
     -- get the date portion of the string
     SET l_date_string = trim(substr( p_assignment , instr( p_assignment , ' ' ) + 1, 10 ));
     SET l_date_string = trim( replace( l_date_string, '(', ' ') );
     SET l_date_string = trim( replace( l_date_string, '-', ' ') );
     
     IF instr( l_date_string, ' ') > 0 THEN
          SET l_date_string = trim( substr( l_date_string, 1, instr( l_date_string, ' ')));
     END IF;

     SET l_assignment_date = str_to_date( l_date_string , '%m/%d/%Y');
     
RETURN l_assignment_date;
END$$ 

DELIMITER ;