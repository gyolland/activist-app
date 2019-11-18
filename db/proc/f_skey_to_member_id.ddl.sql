DROP FUNCTION IF EXISTS f_skey_to_member_id;

DELIMITER $$
/********************************************************************************
f_skey_to_member_id: use surrogate key to locate member id in skey table. Use
        both the skey_long then skey_short if the skey_long fails. If both fail
        return NULL indicating that the record wasn't found.
  Input: SKEY_LONG, SKEY_SHORT both VARCHAR(120).
  Output: Integer MEMBER_ID if found, null if not.
********************************************************************************/

CREATE FUNCTION f_skey_to_member_id(p_skey_long VARCHAR(120), p_skey_short VARCHAR(120))
RETURNS INTEGER
DETERMINISTIC
BEGIN
    DECLARE member_id INT DEFAULT NULL;

    SELECT person_id INTO member_id FROM t_skey WHERE skey_long = p_skey_long;
    IF member_id IS NULL THEN
        -- no match for skey_long, try skey_short
        SELECT person_id INTO member_id FROM t_skey WHERE skey_short = p_skey_short;
    END IF;

    -- SET member_id = @member_id;

RETURN member_id;
END $$

DELIMITER ;