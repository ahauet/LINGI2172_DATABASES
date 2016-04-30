/*
 * AcquireTable
 * IN: a table barcode
 * OUT: a client token
 * PRE: the table is free
 * POST: the table is no longer free
 * POST: issued token can be used for ordering drinks
 *
 * Usage
 * select acquire_table(1);
 */
CREATE OR REPLACE FUNCTION acquire_table(codebar integer) RETURNS integer AS 
$$
	DECLARE
		next_id integer;
		table_is_free boolean;
    BEGIN
		/* We don't need to check if the table is free because we have a UNIQUE constraint on the 'placement' table that ensure that a table can not be reserved by 2 clients at the same time */
	  
		/* If the table is free, generate a token
		 * make the reservation of the table
		 * return the token
		 */
		BEGIN
			next_id := nextval('token_id_seq');
			INSERT INTO client (token_id) VALUES (next_id);
			INSERT INTO placement (client_id, table_id) VALUES (next_id, codebar); /* this statement will raise an error if the table_id is already used by another client */
			return next_id;
		EXCEPTION WHEN unique_violation THEN
			RAISE EXCEPTION 'this table is already reserved';
		END;
	END;
$$ LANGUAGE plpgsql;
	

 