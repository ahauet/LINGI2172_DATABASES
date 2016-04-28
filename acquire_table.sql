CREATE OR REPLACE FUNCTION acquire_table(codebar integer) RETURNS integer AS $$
    DECLARE
      next_id integer := nextval('token_id_seq');
    BEGIN
      INSERT INTO client (token_id) values (next_id);
      INSERT INTO placement (client_id, table_id) values (next_id, codebar);
      return next_id;
    END;
    $$ LANGUAGE plpgsql;
	
	
/* 
 * Usage
 */
 select acquire_table(1);