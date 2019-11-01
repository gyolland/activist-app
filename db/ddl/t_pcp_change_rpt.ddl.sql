CREATE TABLE t_pcp_change_rpt(
    tmpstmp             TIMESTAMP DEFAULT current_timestamp,
    ocvr_voter_id       varchar(14) NOT NULL,
    person_id           int,
    precinct            int,
    precinct_change     boolean DEFAULT false,
    address_change      boolean DEFAULT false,
    returning_pcp       boolean DEFAULT false,
    new_pcp             boolean DEFAULT false,
    removed             boolean DEFAULT false,
    PRIMARY KEY (tmpstmp, ocvr_voter_id)
);