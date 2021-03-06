DROP PROCEDURE IF EXISTS p_report_changes;

DELIMITER //

CREATE PROCEDURE p_report_changes (IN p_report_date DATE)
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE onError INT DEFAULT FALSE;
    DECLARE changed BOOLEAN DEFAULT FALSE;

    DECLARE l_member_id, l_precinct, l_mprecinct, l_stg_id INT DEFAULT NULL;
    DECLARE l_fname, l_middlename, l_lname, l_mfname, l_mmiddlename, l_mlname, l_category VARCHAR(40) DEFAULT NULL;
    DECLARE l_address, l_maddress VARCHAR(100) DEFAULT NULL;
    DECLARE l_status VARCHAR(30) DEFAULT NULL;

    DECLARE c_unmatched VARCHAR(30) DEFAULT 'UNMATCHED';
    DECLARE c_inactive  VARCHAR(30) DEFAULT 'INACTIVE';
    DECLARE c_returning VARCHAR(30) DEFAULT 'RETURNING';
    DECLARE c_current   VARCHAR(30) DEFAULT 'CURRENT';
    DECLARE c_removed   VARCHAR(40) DEFAULT 'REMOVED';
    DECLARE c_new       VARCHAR(40) DEFAULT 'NEW';

    -- cursor to test which members have changed data 
    -- compares person to member stage
    -- test precinct, fname, middlename, lname, residential addresss
    -- also will id returning and removed PCPs -- see derived status column
    DECLARE c_pcp CURSOR FOR
    SELECT  member_id, precinct, fname, middlename, lname, address, 
            mprecinct, mfname, mmiddlename, mlname, mr_address, status, stg_id
      FROM (
        SELECT
              p.id                                  AS member_id
            , p.precinct
            , IFNULL(e.d_fname, p.fname)            AS fname
            , IFNULL(e.d_middlename, p.middlename)  AS middlename
            , IFNULL(e.d_lname, p.lname)            AS lname
            , a.address
            , m.precinct      AS mprecinct
            , m.fname         AS mfname
            , m.middlename    AS mmiddlename
            , m.lname         AS mlname
            , m.r_address     AS mr_address
            -- , r0.term_end_date
            , CASE WHEN m.member_id IS NULL AND r0.term_end_date < now() THEN 'INACTIVE'
                WHEN m.member_id IS NULL THEN 'UNMATCHED' 
                WHEN r0.term_end_date < now() THEN 'RETURNING'
                ELSE 'CURRENT' END AS status 
            , m.stg_id
        FROM t_person p 
        JOIN ( SELECT person_id, max(term_end_date) AS term_end_date  
                    FROM t_person_role     -- return only most recent
                    WHERE role_id = 3         -- PCP role record
            GROUP BY person_id  ) r0 ON p.id = r0.person_id
        JOIN (SELECT * FROM t_address WHERE type = 'RESI') a ON p.id = a.person_id
        LEFT JOIN exception e ON p.id = e.person_id
        LEFT JOIN member_stage m ON p.id = m.member_id
        UNION
		SELECT
              m.member_id
            , NULL  AS precinct
            , NULL  AS fname
            , NULL  AS middlename
            , NULL            AS lname
            , NULL                AS  address
            , m.precinct      AS mprecinct
            , m.fname         AS mfname
            , m.middlename    AS mmiddlename
            , m.lname         AS mlname
            , m.r_address     AS mr_address
            , 'NEW' AS status
            , m.stg_id
		FROM member_stage m
        LEFT JOIN t_person p ON m.member_id = p.id
        WHERE p.id IS NULL
        ) active_member
    WHERE status <> 'INACTIVE' ;


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
    'INSERT INTO change_report(report_date, person_id, category, new_data, old_data, stg_id) VALUES (?, ?, ?, ?, ?, ?)';

    SET @report_date = str_to_date(p_report_date, '%Y-%m-%e');

    OPEN c_pcp;

    pcploop: LOOP
        SET onError = FALSE;
        SET changed = FALSE;
        SET @person_id = NULL;
        SET @new_person_name = NULL;
        SET @old_person_name = NULL;
        SET @category = NULL;
        SET @msg_new = NULL;
        SET @msg_old = NULL;
        SET @stg_id = NULL;

        FETCH c_pcp INTO 
        l_member_id, l_precinct, l_fname, l_middlename, l_lname, l_address,
        l_mprecinct, l_mfname, l_mmiddlename, l_mlname, l_maddress, l_status, l_stg_id;
        IF done = TRUE THEN
            leave pcploop;
        END IF;

        SET @person_id = l_member_id;
        SET @stg_id = l_stg_id ;
        IF l_status <> c_new
        THEN
            SET @old_person_name = REPLACE(CONCAT_WS(' ', l_fname, l_middlename, l_lname), '  ', ' ');
            SET @msg_old = CONCAT_WS(' ', l_precinct, '|', @old_person_name, '|', l_address);
        END IF;
        SET @new_person_name = REPLACE(CONCAT_WS(' ', l_mfname, l_mmiddlename, l_mlname), '  ', ' ');
        SET @msg_new = CONCAT_WS(' ', l_mprecinct, '|', @new_person_name, '|', l_maddress);
        
        CASE l_status
        WHEN c_inactive THEN
            ITERATE pcploop;
        WHEN c_unmatched THEN 
            SET @category = c_removed;
            SET @msg_new = NULL;
        WHEN c_returning THEN
            SET @category = c_returning;
        WHEN c_current THEN
            IF l_precinct <> l_mprecinct THEN
                SET changed = TRUE;
                SET @category = 'PRECINCT';
            END IF;
            IF l_fname <> l_mfname
            OR l_middlename <> l_mmiddlename
            OR l_lname <> l_mlname
            THEN
                SET changed = TRUE;
                SET @category = CONCAT(IFNULL(@category, ''), 'NAME');
                SET @name = CONCAT(l_mfname, ' ', ifnull(l_mmiddlename, ''), ' ', l_mlname);
            END IF;
            IF l_address <> l_maddress THEN
                SET changed = TRUE;
                SET @category = CONCAT(IFNULL(@category, ''), ', ADDRESS');
            END IF;
        WHEN c_new THEN
            SET changed = TRUE;
            SET @category = c_new;
        END CASE;  -- end case

        IF l_status = c_unmatched OR l_status = c_returning OR changed  = TRUE THEN
            START TRANSACTION;
            EXECUTE insert_change USING @report_date, @person_id, @category, @msg_new, @msg_old, @stg_id;
        END IF;

        IF onError = TRUE THEN
            ROLLBACK;
            ITERATE pcploop;
        ELSE
            COMMIT;
        END IF;

    END LOOP; -- pcploop

    CLOSE c_pcp;

    DEALLOCATE PREPARE insert_error;
    DEALLOCATE PREPARE insert_change;
END //

DELIMITER ;