/* find duplicate PCPs
-- This will find PCPs with the same first and last name but different person IDs
-- It's OK to have multiple person role records so the same name with the same persion id
-- but multiple role ids/role names is fine.
-- ocvr_voter_id is included to help identify if two people share a name but are actually 2 people.
-- however, this still might be a duplicate record. Check more data.
-- In most cases, duplicate result from a person joining as a role other than PCP and later
-- becoming a PCP. A likely easy fix is the update the t_person_role table with the person_id that 
-- match the PCP record in t_person_role.
*/
SELECT 
    p.id
  , p.fname
  , p.lname
  , p.ocvr_voter_id
  , r0.role_id
  , r0.term_start_date
  , r0.term_end_date
  , r0.elected
  , r.role_name
  -- , p.*
FROM t_person p 
JOIN 
	(SELECT fname, lname, count(*) AS recs 
		FROM t_person 
	GROUP BY fname, lname
	HAVING count(*) > 1 ) n ON p.fname = n.fname AND p.lname = n.lname
LEFT JOIN t_person_role r0 ON p.id = r0.person_id
JOIN t_role r ON r0.role_id = r.id
ORDER BY p.lname, p.fname;