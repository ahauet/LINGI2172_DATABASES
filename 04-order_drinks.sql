DROP FUNCTION IF EXISTS order_drinks(token integer, orders order_line[]);
DROP TYPE IF EXISTS order_line;

/*
 * A new type can be used to store a tuple of primitive types
 */
CREATE TYPE order_line AS (
	drink_id integer,
	qty integer
);

/*
 * IsTokenValid
 * IN: a token
 * OUT: TRUE if the token is a valid token that can be used to order drinks
 * OUT : FALSE otherwise
 */
CREATE OR REPLACE FUNCTION is_token_valid(token integer) RETURNS boolean AS 
$$
    DECLARE
		placement_row record;
    BEGIN
		SELECT * INTO placement_row FROM placement WHERE client_id = token ;
		IF NOT FOUND THEN
			return FALSE;
		ELSE
			return TRUE;
		END IF;
    END;
$$ LANGUAGE plpgsql;
	

/*
 * OrderDrinks
 * IN: a client token
 * IN: a list of order_line 
 * OUT: the unique number if the created order
 * PRE: the client token is valid and correspond to an occupied table
 * POST: the order is created, its number is the one returned
 *
 * Usage
  select order_drinks(1, array[
	(1,2),
	(2,2)
	]::order_line[]);
 */
CREATE OR REPLACE FUNCTION order_drinks(token integer, orders order_line[]) RETURNS integer AS 
$$
    DECLARE
		next_order_id integer := nextval('order_id_seq');
		my_order_line order_line;
		token_is_valid boolean;
    BEGIN
		/* First, check if the token exists in the 'placement' table', if not raise an exception */
		token_is_valid := is_token_valid(token);
		IF token_is_valid THEN
			/* */
			INSERT INTO "order" (order_id, order_time, passes_by) VALUES (next_order_id, 'now', token);
			FOREACH my_order_line IN ARRAY orders
			LOOP
				INSERT INTO ordered_drink (order_id, drink_id, qty) VALUES (next_order_id, my_order_line.drink_id, my_order_line.qty);
			END LOOP;
			return next_order_id;
		ELSE
			RAISE EXCEPTION 'the provided token is not valid';
		END IF;
    END;
$$ LANGUAGE plpgsql;
	
