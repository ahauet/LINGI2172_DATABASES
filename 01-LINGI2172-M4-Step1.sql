/*
 * This script generates the schema of the database for the step 1 of the M4
 */

DROP TABLE IF EXISTS payment;
DROP TABLE IF EXISTS ordered_drink;
DROP TABLE IF EXISTS "order";
DROP TABLE IF EXISTS drink;
DROP TABLE IF EXISTS placement;
DROP TABLE IF EXISTS client;
DROP TABLE IF EXISTS "table";

DROP SEQUENCE IF EXISTS table_id_seq;
DROP SEQUENCE IF EXISTS token_id_seq;
DROP SEQUENCE IF EXISTS drink_id_seq;
DROP SEQUENCE IF EXISTS order_id_seq;
DROP SEQUENCE IF EXISTS payment_id_seq;


CREATE SEQUENCE table_id_seq;
CREATE TABLE "table" (
    table_id integer NOT NULL PRIMARY KEY DEFAULT nextval('table_id_seq')
    /*codebar varchar(12) NOT NULL*/
);

CREATE SEQUENCE token_id_seq;
CREATE TABLE client (
    token_id integer NOT NULL PRIMARY KEY DEFAULT nextval('token_id_seq')
    /*placed_at integer NOT NULL UNIQUE REFERENCES "table"(table_id)*/
);

/* The UNIQUE constraint on table_id ensure that a table will not be reserved by 2 clients at the same time */
CREATE TABLE placement (
    client_id integer NOT NULL REFERENCES client(token_id),
    table_id integer NOT NULL UNIQUE REFERENCES "table"(table_id),
    PRIMARY KEY (client_id, table_id)
) ;

CREATE SEQUENCE drink_id_seq;
CREATE TABLE drink (
    drink_id integer NOT NULL PRIMARY KEY DEFAULT nextval('drink_id_seq'),
    price numeric(18,2) NOT NULL,
    name varchar(30) NOT NULL,
    description varchar(500)
);

CREATE SEQUENCE order_id_seq;
CREATE TABLE "order" (
    order_id integer NOT NULL PRIMARY KEY DEFAULT nextval('order_id_seq'),
    order_time date NOT NULL,
    passes_by integer NOT NULL REFERENCES client(token_id)
);


CREATE TABLE ordered_drink (
    order_id integer NOT NULL REFERENCES "order"(order_id),
    drink_id integer NOT NULL REFERENCES drink(drink_id),
    qty integer DEFAULT 0 NOT NULL,
    PRIMARY KEY (order_id, drink_id)
) ;

CREATE SEQUENCE payment_id_seq;
CREATE TABLE payment (
    payment_id integer NOT NULL PRIMARY KEY DEFAULT nextval('payment_id_seq'),
    amount_paid numeric(18,2) NOT NULL,
    made_by integer NOT NULL REFERENCES client(token_id)
);


