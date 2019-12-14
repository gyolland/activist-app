DROP PROCEDURE IF EXISTS p_report_new_pcp;

DELIMITER //

CREATE PROCEDURE p_report_new_pcp (IN p_report_date DATE)
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE onError INT DEFAULT FALSE;
    DECLARE changed BOOLEAN DEFAULT FALSE;

    DECLARE l_member_id, l_precinct, l_mprecinct INT DEFAULT NULL;
    DECLARE l_fname, l_middlename, l_lname, l_mfname, l_mmiddlename, l_mlname, l_category VARCHAR(40) DEFAULT NULL;
    DECLARE l_address, l_maddress VARCHAR(100) DEFAULT NULL;
    DECLARE l_status VARCHAR(30) DEFAULT NULL;

    -- cursor: identify new pcps
    DECLARE c_new CURSOR FOR
    SELECT
          m.member_id
        , m.precinct
        , m.fname
        , m.middlename
        , m.lname
        , m.r_address 
        , 'NEW' AS status
      FROM member_stage m
      LEFT JOIN t_person p ON m.member_id = p.id
     WHERE p.id IS NULL 
    UNION   -- Use where not exists to subquery to remove current or prevous pcps
    SELECT  -- find non-pcp members that are becoming pcps
          m.member_id
        , m.precinct
        , m.fname
        , m.middlename
        , m.lname
        , m.r_address 
        , 'NEW' AS status
      FROM t_person pers 
      JOIN member_stage m ON pers.id = m.member_id
      JOIN t_person_role r00 ON pers.id = r00.person_id
     WHERE  NOT EXISTS (SELECT 'X'                      -- inactive is not included to account for
                          FROM t_person_role t0         -- person with non-pcp records, but no 
                         WHERE pers.id = t0.person_id   -- previous pcp role.
                           AND t0.role_id = 3);         -- 3 = pcp

    -- condition/exception handlers
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        GET CURRENT DIAGNOSTICS CONDITION 1
            @errno = MYSQL_ERRNO, @msg = MESSAGE_TEXT;

        ROLLBACK;

        SET @msg = CONCAT(@errno, ': ', @msg);

        SET onError = TRUE;

        -- person_id, logmessage
        EXECUTE insert_error USING @person_id, @msg;
    END;

    PREPARE insert_error
    FROM
    'INSERT INTO error_log(person_id, logmessage) VALUES(?, ?)';

    PREPARE insert_change
    FROM 
    'INSERT INTO change_report(report_date, person_id, category, message) VALUES (?, ?, ?, ?)';

    SET @report_date = str_to_date(p_report_date, '%Y-%m-%e');

    OPEN c_new ;

    newpcploop: LOOP 
        SET onError = FALSE;
        SET changed = FALSE;
        SET @person_id = NULL;
        SET @category = NULL;
        SET @msg = NULL;

        FETCH c_new INTO 
        l_member_id, l_precinct, l_fname, l_middlename, l_lname, l_address, l_status ;
        IF done = TRUE THEN
            leave newpcploop;
        END IF;

        SET @person_id = l_member_id ; 
        SET @category = l_status ;
        SET @msg = CONCAT_WS(' ', l_fname, ifnull(l_middlename, ''), l_lname, l_precinct, l_address) ;
        
        START TRANSACTION;

        EXECUTE insert_change USING @report_date, @person_id, @category, @msg ;

        IF onError = TRUE THEN
            ITERATE pcploop;
        ELSE
            COMMIT;
        END IF;

    END LOOP; -- newpcploop

    CLOSE c_pcp;

    DEALLOCATE PREPARE insert_error ;
    DEALLOCATE PREPARE insert_change ;
END //

DELIMITER ;