/*
 * PayTable
 * IN: a client token
 * IN: an amount paid
 * OUT: 
 * PRE: the client token is valid
 * PRE: The input amount >= amount due for the table
 * POST: the table is released
 * POST: the client token can no longer be used to order drinks
 * 
 * Usage
 * select pay_table(9, 10.0)
 */
CREATE OR REPLACE FUNCTION pay_table(token integer, amount numeric(18,2)) RETURNS void AS
$$
	DECLARE
		token_is_valid boolean;
		amount_due numeric(18,2);
	BEGIN
		/* First, check if the token exists in the 'placement' table', if not raise an exception */
		token_is_valid := is_token_valid(token);
		amount_due := get_total_for_token(token);
		IF token_is_valid THEN
			/* Then check if the given amount is enought */
			IF amount >= amount_due THEN
				INSERT INTO payment (amount_paid, made_by) VALUES (amount, token);
				DELETE FROM placement WHERE client_id = token;
				RETURN;
			ELSE
				RAISE EXCEPTION 'the given amount must be greater or equal to %', amount_due;
			END IF;
		ELSE
			RAISE EXCEPTION 'the provided token is not valid';
		END IF;
	END;
$$ LANGUAGE plpgsql;
