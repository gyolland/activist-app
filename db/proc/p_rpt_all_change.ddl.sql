DROP PROCEDURE IF EXISTS p_rpt_all_change;

DELIMITER //

CREATE PROCEDURE p_rpt_all_change(IN p_report_date DATE)
BEGIN

    TRUNCATE TABLE change_report;

    CALL p_report_new_pcp(p_report_date);

    CALL p_report_changes(p_report_date);

    SELECT * FROM change_report ORDER BY category;
END //

DELIMITER ;