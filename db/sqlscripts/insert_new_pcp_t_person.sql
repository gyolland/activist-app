-- Step 1: Insert minimal data into t_person from new OCVR records.
-- The minimum data is: 
-- PRECINCT, OCVR_VOTER_ID, FNAME, LNAME, MIDDLENAME, GENDER, ASSIGNMENT
-- The reason to do this is to 
-- generate the ID in t_person and use that ID in t_person_stage to fill out the
-- records from different sources
-- this is an incomplete selection based on joining the PCP Applicant Form data
-- and ocvr data where no t_person record exists.

-- Step 1: Initial insert into t_person to generate ID column
-- before insert, get the max id from t_person and make note of the number
SELECT MAX(id) FROM t_person;

START TRANSACTION;

INSERT INTO t_person (precinct, ocvr_voter_id, fname, lname, middlename, gender, assignment)
SELECT 
	  o.precinct
    , o.ocvr_voter_id
    , f_parse_firstname(o.fname) AS fname
    , trim(o.lname) AS lname
    , f_parse_lastname(o.fname) AS middlename
    , right(o.status_gender, 1) AS gender
    , o.assignment
FROM t_import_ocvr_tmp o
LEFT JOIN t_person p USING(ocvr_voter_id)
WHERE p.id is NULL ;

-- Step 2: insert newly added t_person records into t_person_stage
 INSERT INTO t_person_stage
 SELECT * FROM t_person WHERE id > XXX;

-- Step 3: Parse Assignment field to determine elected or appointed and 
 -- insert t_person_role records for the new PCPs
 INSERT INTO t_person_role(person_id, role_id, certified_pcp, elected, term_start_date, term_end_date, inactive)
 SELECT
	ps.id AS person_id
  , 3 AS role_id -- role_id for PCP
  , TRUE AS certified_pcp
  , CASE WHEN instr(lcase(ps.assignment), 'elected') > 0 THEN TRUE ELSE FALSE END AS elected
  , f_get_assignment_date(ps.assignment) AS term_start_date
  , (SELECT max(term_end_date) FROM t_person_role WHERE role_id = 3) AS term_end_date
  , FALSE as inactive
FROM t_person_stage ps;

-- inspect before commit
-- ROLLBACK;
-- COMMIT;
 
-- Step 4: Enhance date in t_person_stage with date from PCP Applicant Form
SELECT 
	  o.precinct
    , o.ocvr_voter_id
    -- , o.fname AS fname_unparsed
    , f_parse_firstname(o.fname) AS fname
    -- , f.fname as ffname
    , trim(o.lname) AS lname
    -- , f.lname AS flname
    , f_parse_lastname(o.fname) AS middlename
    , right(o.status_gender, 1) AS gender
    , f.phone as primary_phone
    , f.email as primary_email
    , o.assignment
FROM t_import_ocvr_tmp o
LEFT JOIN t_import_pcp_applicant_form f ON o.precinct = f.precinct 
          AND trim(o.lname) = trim(f.lname) 
          -- AND f_parse_firstname(o.fname) = f_parse_firstname(f.fname) 
LEFT JOIN t_person p USING(ocvr_voter_id)
WHERE p.id is NULL ;

-- Step 5: Enhance date in t_person_stage with date from PCP Applicant Form

-- Step 6: Produce draft of New Master PCP

