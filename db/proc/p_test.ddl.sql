DROP PROCEDURE IF EXISTS p_test;

DELIMITER //

CREATE PROCEDURE p_test (IN p_state_voter_id VARCHAR(14), OUT person_id INT, inactive BOOLEAN)
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE onError INT DEFAULT FALSE;

    DECLARE v_person_id INT DEFAULT NULL;
    DECLARE v_inactive BOOLEAN DEFAULT FALSE;

    prepare test_prep from 
    'select p.id as person_id, r0.inactive INTO ?, ?                                                    
    from t_person p                                                                                                              
    left join (select person_id, inactive, max(term_end_date) term_end_date                                                      
    from t_person_role                                                                                                           
    where role_id = 3                                                                                                            
    group by person_id, inactive ) r0 ON p.id = r0.person_id Where ocvr_voter_id = ?';

    SET @vid = p_state_voter_id;

    EXECUTE test_prep USING @person_id, @inactive, @vid ;

    SET person_id = @person_id;
    SET inactive = @inactive;

    DEALLOCATE PREPARE test_prep;

END //

DELIMITER ;
