-- cursor to test which members have changed data 
-- compares person to member stage
-- test precinct, fname, middlename, lname, residential addresss
-- also will id returning and removed PCPs -- see derived status column
DECLARE c_pcp CURSOR FOR
SELECT  member_id, precinct, fname, middlename, lname, address, 
        mprecinct, mfname, mmiddlename, mlname, mr_address, status
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
    FROM t_person p 
    JOIN ( SELECT person_id, max(term_end_date) AS term_end_date  
                FROM t_person_role     -- return only most recent
                WHERE role_id = 3         -- PCP role record
        GROUP BY person_id  ) r0 ON p.id = r0.person_id
    JOIN (SELECT * FROM t_address WHERE type = 'RESI') a ON p.id = a.person_id
    LEFT JOIN exception e ON p.id = e.person_id
    LEFT JOIN member_stage m ON p.id = m.member_id) active_member
WHERE status <> c_inactive ;


-- cursor: identify new pcps
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