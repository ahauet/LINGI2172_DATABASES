DROP FUNCTION IF EXISTS issue_ticket(token integer);
DROP TYPE IF EXISTS ticket;
DROP TYPE IF EXISTS ticket_line;

/*
 * A special type used to associated a drink name and a quantity
 */
CREATE TYPE ticket_line AS (
	name varchar(30),
	qty integer
);

/*
 * A special type used to associated a list of ticket_line and a total price
 */
CREATE TYPE ticket AS (
	total numeric(18,2),
	lines ticket_line[]
);

/*
 * GetTotalForToken
 * IN: token
 * OUT: the total amount due
 */
CREATE OR REPLACE FUNCTION get_total_for_token(token integer) RETURNS numeric(18,2) AS
$$
	DECLARE
		total_value numeric(18,2);
	BEGIN
		select sum(d.price* od.qty) INTO total_value as total
			from drink d, ordered_drink od, "order" o
			where d.drink_id = od.drink_id 
				and o.order_id = od.order_id
				and o.passes_by = token;
		RETURN total_value;
	END;
$$ LANGUAGE plpgsql;

/*
 * GetTicketLinesForToken
 * IN: token
 * OUT: an array of type ticket_line
 */
CREATE OR REPLACE FUNCTION get_ticket_lines_for_token(token integer) RETURNS ticket_line[] AS
$$
	DECLARE
		array_value ticket_line[];
		row_value RECORD;
	BEGIN
		FOR row_value IN select distinct(d.name) as name, sum(od.qty) as qty
							from drink d, ordered_drink od, "order" o
							where d.drink_id = od.drink_id 
								and o.order_id = od.order_id
								and o.passes_by = token
							group by d.name
		LOOP
			array_value := array_append(array_value, (row_value.name, row_value.qty)::ticket_line);
		END LOOP;
		RETURN array_value;
	END;
$$ LANGUAGE plpgsql;

/*
 * IssueTicket
 * IN: a client token
 * OUT: the ticket to be paid, with a summary of orders (which drinks in which quantities) and total amount to pay
 * PRE: the client token is valid and correspond to an occupied table
 * POST: issued ticke correspond to all (and only) ordered drinks at that table
 *
 * Usage
 * 
 */
CREATE OR REPLACE FUNCTION issue_ticket(token integer) RETURNS ticket AS 
$$
	DECLARE
		token_is_valid boolean;
		the_ticket ticket;
    BEGIN
		/* First, check if the token exists in the 'placement' table', if not raise an exception */
		token_is_valid := is_token_valid(token);
		IF token_is_valid THEN
			the_ticket := (get_total_for_token(token), get_ticket_lines_for_token(token))::ticket;
			return the_ticket;
		ELSE
			RAISE EXCEPTION 'the provided token is not valid';
		END IF;
	END;
$$ LANGUAGE plpgsql;
	

/* POST-IT BELOW */
 /* Use this to select all the order_lines for a given token
 select d.name, od.qty
from drink d, ordered_drink od, "order" o
where d.drink_id = od.drink_id 
	and o.order_id = od.order_id
	and o.passes_by = 2
*/
/* Use this to select all the drinks ordered for a token and their quantities
select distinct(d.name) as name, sum(od.qty) as qty
from drink d, ordered_drink od, "order" o
where d.drink_id = od.drink_id 
	and o.order_id = od.order_id
	and o.passes_by = 2
group by d.name
*/
/* Use this to compute the total for a given token
select sum(d.price* od.qty) as total
from drink d, ordered_drink od, "order" o
where d.drink_id = od.drink_id 
	and o.order_id = od.order_id
	and o.passes_by = 2
*/