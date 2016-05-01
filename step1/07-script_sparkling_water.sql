CREATE OR REPLACE FUNCTION sparkling_water_scenario() RETURNS VOID AS
$$
	DECLARE
		token integer;
	BEGIN
		token := acquire_table(2);
		PERFORM order_drinks(token, array[(6, 1)]::order_line[]);
		PERFORM issue_ticket(token);
		PERFORM order_drinks(token, array[(6, 1)]::order_line[]);
		PERFORM pay_table(token, 10.0);
		RETURN;
	END
$$ LANGUAGE plpgsql;