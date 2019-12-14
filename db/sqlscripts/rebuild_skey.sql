-- rebuild_skey: truncates and repopulates a surrogate key table 
TRUNCATE t_skey;

INSERT INTO t_skey (person_id, fname, middlename, lname, skey_long, skey_short)
SELECT 
	p.id AS person_id
  , p.fname
  , p.middlename
  , p.lname
  , f_skey(ifnull(e.d_fname, p.fname), ifnull(e.d_middlename, p.middlename), ifnull(e.d_lname, p.lname)) as skey_long
  , f_skey(ifnull(e.d_fname, p.fname), '',  ifnull(e.d_lname, p.lname)) as skey_short
FROM t_person p
LEFT JOIN exception e ON p.id = e.person_id
ORDER BY p.id ;

SELECT skey_short, count(*) recs
FROM t_skey 
GROUP BY skey_short
HAVING count(*) > 1;