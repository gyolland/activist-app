DROP FUNCTION IF EXISTS f_get_person_role_id;

DELIMITER $$
/********************************************************************************
f_get_person_role_id: return the t_person_role.id of the most recent record of
type the role_id and inactive status for a given t_person.id.
********************************************************************************/

CREATE FUNCTION f_get_person_role_id(p_person_id INT, p_role_id INT, p_inactive BOOLEAN)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE l_return INT DEFAULT 0;

    SELECT id 
      INTO @person_role_id
      FROM t_person_role
     WHERE person_id = p_person_id
       AND role_id   = p_role_id
       AND inactive  = p_inactive;

    RETURN l_return;
END$$

DELIMITER ;