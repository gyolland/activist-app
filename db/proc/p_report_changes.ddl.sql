DROP PROCEDURE IF EXISTS p_report_changes;

DELIMITER //

CREATE PROCEDURE p_report_changes (IN p_report_date DATE)
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE onError INT DEFAULT FALSE;
    DECLARE changed BOOLEAN DEFAULT FALSE;

    DECLARE l_member_id, l_precinct, l_mprecinct INT DEFAULT NULL;
    DECLARE l_fname, l_middlename, l_lname, l_mfname, l_mmiddlename, l_mlname, l_category VARCHAR(40) DEFAULT NULL;
    DECLARE l_address, l_maddress VARCHAR(100) DEFAULT NULL;
    DECLARE l_status VARCHAR(30) DEFAULT NULL;

    DECLARE c_unmatched VARCHAR(30) DEFAULT 'UNMATCHED';
    DECLARE c_returning VARCHAR(30) DEFAULT 'RETURNING';
    DECLARE c_current   VARCHAR(30) DEFAULT 'CURRENT';
    DECLARE c_removed   VARCHAR(40) DEFAULT 'REMOVED';

    -- cursor to test which members have changed data 
    -- compares person to member stage
    -- test precinct, fname, middlename, lname, residential addresss
    -- also will id returning and removed PCPs -- see derived status column
    DECLARE c_pcp CURSOR FOR
    SELECT
        p.id            AS member_id
        , p.precinct
        , IFNULL(e.d_fname, p.fname) AS fname
        , IFNULL(e.d_middlename, p.middlename) AS middlename
        , IFNULL(e.d_lname, p.lname) AS lname
        , a.address
        , m.precinct      AS mprecinct
        , m.fname         AS mfname
        , m.middlename    AS mmiddlename
        , m.lname         AS mlname
        , m.r_address     AS mr_address
        -- , r0.term_end_date
        , CASE WHEN m.member_id IS NULL THEN 'UNMATCHED' 
                    WHEN r0.term_end_date < now() THEN 'RETURNING'
                ELSE 'CURRENT' END AS status
    FROM t_person p 
    JOIN ( SELECT person_id, max(term_end_date) AS term_end_date  
                FROM t_person_role     -- return only most recent
                WHERE role_id = 3         -- PCP role record
        GROUP BY person_id  ) r0 ON p.id = r0.person_id
    JOIN (SELECT * FROM t_address WHERE type = 'RESI') a ON p.id = a.person_id
    LEFT JOIN exception e ON p.id = e.person_id
    LEFT JOIN member_stage m ON p.id = m.member_id ;


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

    OPEN c_pcp;

    pcploop: LOOP
        SET onError = FALSE;
        SET changed = FALSE;
        SET @person_id = NULL;
        SET @category = NULL;
        SET @msg = NULL;

        FETCH c_pcp INTO 
        l_member_id, l_precinct, l_fname, l_middlename, l_lname, l_address,
        l_mprecinct, l_mfname, l_mmiddlename, l_mlname, l_maddress, l_status;
        IF done = TRUE THEN
            leave pcploop;
        END IF;

        SET @person_id = l_member_id;
        
        CASE l_status
        WHEN c_unmatched THEN 
            SET @category = c_removed;
            SET @msg = CONCAT( l_fname, ' ', l_lname );
        WHEN c_returning THEN
            SET @category = c_returning;
            SET @msg = CONCAT( l_precinct, ' ', l_fname, ' ', l_lname );
        WHEN c_current THEN
            IF l_precinct <> l_mprecinct THEN
                SET changed = TRUE;
                SET @category = 'PRECINCT';
                SET @msg = CONCAT('new precinct: ', l_mprecinct) ;
            END IF;
            IF l_fname <> l_mfname
            OR l_middlename <> l_mmiddlename
            OR l_lname <> l_mlname
            THEN
                SET changed = TRUE;
                SET @category = CONCAT(IFNULL(@category, ''), 'NAME');
                SET @name = CONCAT(l_mfname, ' ', ifnull(l_mmiddlename, ''), ' ', l_mlname);
                SET @msg = CONCAT(IFNULL(@msg, ''), ' new name: ', @name);
            END IF;
            IF l_address <> l_maddress THEN
                SET changed = TRUE;
                SET @category = CONCAT(IFNULL(@category, ''), ', ADDRESS');
                SET @msg = CONCAT(IFNULL(@msg, ''), 'new address: ', l_maddress);
            END IF;
        END CASE;  -- end case

        IF l_status = c_unmatched OR l_status = c_returning OR changed  = TRUE THEN
            START TRANSACTION;
            EXECUTE insert_change USING @report_date, @person_id, @category, @msg;
        END IF;

        IF onError = TRUE THEN
            ITERATE pcploop;
        ELSE
            COMMIT;
        END IF;

    END LOOP; -- pcploop

    CLOSE c_pcp;

    DEALLOCATE PREPARE insert_change;
END //

DELIMITER ;