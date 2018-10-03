CREATE OR REPLACE VIEW v_address AS 
SELECT p.id AS person_id
      , ifnull(ma.address,ra.address) AS mailing_address
      , ifnull(ma.city,ra.city) AS mailing_city
      , ifnull(ma.state,ra.state) AS mailing_state
      , ifnull(ma.zip5,ra.zip5) AS mailing_zip
      , ra.address AS residential_address
      , ra.city AS residential_city
      , ra.state AS residential_state
      , ra.zip5 AS residential_zip 
  FROM ((t_person p 
  JOIN (SELECT t_address.person_id AS person_id
  	         , t_address.address AS address
  	         , t_address.city AS city
  	         ,  t_address.state AS state
  	         , (CASE WHEN isnull(t_address.zip4) THEN t_address.zip5 ELSE concat(t_address.zip5,'-',t_address.zip4) END) AS zip5 
  	      FROM t_address 
  	     WHERE (t_address.type = 'RESI')) ra ON((p.id = ra.person_id))) 
     LEFT JOIN 
       (SELECT t_address.person_id AS person_id
       	     , t_address.address AS address
       	     , t_address.city AS city
       	     , t_address.state AS state
       	     ,(CASE WHEN isnull( t_address.zip4) THEN  t_address.zip5 ELSE concat( t_address.zip5,'-', t_address.zip4) END) AS zip5 
       	  FROM  t_address 
       	 WHERE ( t_address.type = 'MAIL')) ma ON((p.id = ma.person_id)));