PREPARE insert_error
FROM
'INSERT INTO error_log(person_id, logmessage) VALUES(?, ?)';

PREPARE inactivate_role
FROM 
'UPDATE t_person_role SET term_end_date = ?, inactive = FALSE WHERE id = ?' ;

PREPARE insert_role
FROM
'INSERT INTO t_person_role (person_id, role_id, certified_pcp, elected, term_start_date, term_end_date, inactive)
    VALUES (?, ?, ?, ?, ?, ?, ?)' ;

PREPARE update_address
FROM
'UPDATE t_address SET address = ? , city = ?, state = ?,  zip5 = ?, zip4 = ? WHERE person_id = ? AND type = ?'; 

PREPARE update_person_for_precinct_change
FROM 
'UPDATE t_person SET vanprecinct = ?, precinct = ?, assignment = ? WHERE id = ? ' ;

START TRANSACTION;
COMMIT ;
