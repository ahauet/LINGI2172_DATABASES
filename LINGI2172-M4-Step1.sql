--PostgreSQL Maestro 15.4.0.3
------------------------------------------
--Host     : localhost
--Database : LINGI2172-M4-Step1

DROP TABLE IF EXISTS payment;
DROP TABLE IF EXISTS ordered_drink;
DROP TABLE IF EXISTS "order";
DROP TABLE IF EXISTS drink;
DROP TABLE IF EXISTS client;
DROP TABLE IF EXISTS "table";



CREATE TABLE "table" (
    table_id integer NOT NULL PRIMARY KEY,
    codebar varchar(12) NOT NULL
);


CREATE TABLE client (
    token_id integer NOT NULL PRIMARY KEY,
    placed_at integer NOT NULL UNIQUE REFERENCES "table"(table_id)
);


CREATE TABLE drink (
    drink_id integer NOT NULL PRIMARY KEY,
    price numeric(18,2) NOT NULL,
    name varchar(30) NOT NULL,
    description varchar(500)
);


CREATE TABLE "order" (
    order_id integer NOT NULL PRIMARY KEY,
    order_time date NOT NULL,
    passes_by integer NOT NULL REFERENCES client(token_id)
);


CREATE TABLE ordered_drink (
    order_id integer NOT NULL REFERENCES "order"(order_id),
    drink_id integer NOT NULL REFERENCES drink(drink_id),
    qty integer DEFAULT 0 NOT NULL,
    PRIMARY KEY (order_id, drink_id)
) ;



CREATE TABLE payment (
    payment_id integer NOT NULL PRIMARY KEY,
    amount_paid numeric(18,2) NOT NULL,
    made_by integer NOT NULL REFERENCES client(token_id)
);


