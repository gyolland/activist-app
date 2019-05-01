SELECT substr(gender, 1, 1) AS gender,  count(*) PCPs
FROM t_import_ocvr_tmp o 
GROUP BY gender WITH ROLLUP;

SELECT gender,  count(*) PCPs
FROM t_person p
JOIN t_person_role r0 ON p.id = r0.person_id
WHERE r0.role_id = 3 -- PCP
AND r0.inactive = FALSE 
GROUP BY gender WITH ROLLUP;

SELECT gender, count(*) PCPs
FROM v_current_pcp
GROUP BY gender WITH ROLLUP;
