DROP FUNCTION IF EXISTS order_drinks(token integer, orders order_line[]);
DROP TYPE IF EXISTS order_line;
CREATE TYPE order_line AS (
	drink_id integer,
	qty integer
);

CREATE OR REPLACE FUNCTION order_drinks(token integer, orders order_line[]) RETURNS integer AS $$
    DECLARE
      next_order_id integer := nextval('order_id_seq');
	  my_order_line order_line;
    BEGIN
      INSERT INTO "order" (order_id, order_time, passes_by) values (next_order_id, 'now', token);
	  FOREACH my_order_line IN ARRAY orders
	  LOOP
		INSERT INTO ordered_drink (order_id, drink_id, qty) values (next_order_id, my_order_line.drink_id, my_order_line.qty);
	  END LOOP;
      return next_order_id;
    END;
    $$ LANGUAGE plpgsql;
	
	
/* 
 * Usage
 */
 select order_drinks(1, array[
	(1,2),
	(2,2)
]::order_line[]);