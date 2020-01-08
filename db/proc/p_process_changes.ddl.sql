/*
messaging
Removed:
removed:  XXXX | Name Name Name
- id t_person_role record
- update t_person_role record

New:
newpcp: XXXX | Name Name Name | address
- check for member id: update t_person | insert into t_person
- collect person id if member id is null, else use member id
- insert into t_person_role
- insert into address

precinct: 1234 | Name Name Name | address
address: 

Returning:
returning: XXXX | Name Name Name | address
*/

procedure: 
DROP PROCEDURE IF EXISTS p_process_changes;

DELIMITER //

CREATE PROCEDURE p_process_changes(IN p_report_date DATE)
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE onError INT DEFAULT FALSE;

    DECLARE v_person_id INT DEFAULT NULL;
    DECLARE v_inactive BOOLEAN DEFAULT FALSE;

    DECLARE l_stg_id, l_member_id, l_precinct INT DEFAULT NULL;
    DECLARE l_fname, l_midname, l_lname, l_city, l_assignment VARCHAR(40) DEFAULT NULL;
    DECLARE l_suffix VARCHAR(10) DEFAULT NULL;
    DECLARE l_voter_id VARCHAR(14) DEFAULT NULL;
    DECLARE l_address, l_category VARCHAR(100) DEFAULT NULL;
    DECLARE l_state CHAR(2) DEFAULT NULL;
    DECLARE l_zip VARCHAR(15) DEFAULT NULL;
    DECLARE l_start_date, l_end_date DATE DEFAULT NULL;

    DECLARE c_unmatched VARCHAR(30) DEFAULT 'UNMATCHED';
    DECLARE c_inactive  VARCHAR(30) DEFAULT 'INACTIVE';
    DECLARE c_returning VARCHAR(30) DEFAULT 'RETURNING';
    DECLARE c_current   VARCHAR(30) DEFAULT 'CURRENT';
    DECLARE c_removed   VARCHAR(40) DEFAULT 'REMOVED';
    DECLARE c_new       VARCHAR(40) DEFAULT 'NEW';

    DECLARE c_upd CURSOR FOR
    SELECT -- select records where change report has person_id
        m.stg_id, m.member_id, m.fname, m.middlename, m.lname, m.suffix, m.precinct, 
        m.voter_id, m.r_address, m.r_city, m.r_state, m.r_zip, m.assignment, 
        m.start_date, m.end_date, cr.category
      FROM member_stage m
      JOIN(SELECT stg_id, person_id, report_date, category 
             FROM change_report 
            WHERE person_id IS NOT NULL) cr ON m.member_id = cr.person_id
     WHERE cr.report_date = p_report_date   
    UNION
    SELECT -- get new pcps as ID'd by null person_id in change report
        m.stg_id, m.member_id, m.fname, m.middlename, m.lname, m.suffix, m.precinct, 
        m.voter_id, m.r_address, m.r_city, m.r_state, m.r_zip, m.assignment, 
        m.start_date, m.end_date, cr.category
    FROM member_stage m
    JOIN (SELECT stg_id, person_id, report_date, category
            FROM change_report 
           WHERE person_id IS NULL)  cr USING(stg_id)
    WHERE cr.report_date = p_report_date
    UNION
      SELECT -- get data for removed pcps
        null AS stg_id, p.id AS member_id, p.fname, p.middlename, p.lname, p.suffix, p.precinct, 
        p.ocvr_voter_id AS voter_id, null AS r_address, null AS r_city, null AS r_state, null AS r_zip, p.assignment, 
        null AS start_date, p_report_date AS end_date, cr.category
    FROM t_person p 
    JOIN (SELECT stg_id, person_id, report_date, category
            FROM change_report 
           WHERE category = c_removed) cr ON p.id = cr.person_id
    WHERE cr.report_date = p_report_date;

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

    -- prepared statements
    PREPARE insert_error
    FROM
      'INSERT INTO error_log(person_id, logmessage) VALUES(?, ?)';

    PREPARE insert_change_log
    FROM
      'INSERT INTO t_change_log(person_id, person_role_id, action, logmessage) VALUES (?, ?, ?, ?)';

    PREPARE insert_person
    FROM
      'INSERT INTO t_person (fname, middlename, lname, suffix, precinct, ocvr_voter_id, assignment) VALUES (?, ?, ?, ?, ?, ?, ?)';
    
    PREPARE update_person
    FROM
      'UPDATE t_person SET precinct = ?, assignment = ? WHERE id = ?';

    PREPARE insert_person_role
    FROM
      'INSERT INTO t_person_role(person_id, role_id, certified_pcp, elected, term_start_date, term_end_date, inactive)
      VALUES(?, ?, ?, ?, ?, ?, ?)';
    
    PREPARE insert_address
    FROM 
      'INSERT INTO t_address (person_id, type, address, city, state, zip5, zip4) VALUES(?, ?, ?, ?, ?, ?, ?)';
    
    PREPARE update_address
    FROM
      'UPDATE t_address SET address = ?, city = ?, state = ?, zip5 = ?, zip4 = ? WHERE person_id = ? AND type = ?';

    OPEN c_upd;

    upd: LOOP
      SET @person_id = NULL;
      SET @prid = NULL;

      /*FETCH c_upd INTO l_stg_id, l_member_id, l_fname, l_middlename, l_lname, l_suffix, l_precinct, 
        l_voter_id, l_address, l_city, l_state, l_zip, l_assignment, 
        l_start_date, l_end_date, l_category; */
      FETCH c_upd INTO @stg_id, @member_id, @fname, @middlename, @lname, @suffix, @precinct, 
        @voter_id, @address, @city, @state, @zip, @assignment, @start_date, @end_date, @category;
        IF done = TRUE THEN
            leave newpcp;
        END IF; 

      IF l_category = c_removed
      THEN
        SET @err = NULL, @msg = NULL;
        START TRANSACTION;
        CALL p_inactivate_member(@member_id, p_report_date, @err, @msg);
        IF @err IS FALSE
        THEN
            COMMIT;
            ITERATE upd;
        ELSE
            ROLLBACK;
            SET @msg = CONCAT(c_removed, ': ', @msg);
            EXECUTE insert_error USING @member_id, @msg;
            ITERATE upd;
        END IF;

      END IF;

      IF l_category = c_new
      THEN
        IF l_member_id IS NULL
          -- null member id insert t_person
          EXECUTE insert_person USING @fname, @middlename, @lname, @suffix, @precinct, @voter_id, @assignment;

          --  capture t_person id
          SET @member_id = LAST_INSERT_ID();
        THEN
        -- has member id, update t_person
          EXECUTE update_person USING @precinct, @assignment @member_id;
        END IF;
        
        -- addd person role record
        EXECUTE insert_person_role USING @member_id, 3, true, elected, @start_date, @end_date, false;

        -- add/update address
      END IF;


    END LOOP; -- upd

    CLOSE c_upd;
END //

DELIMITER ;