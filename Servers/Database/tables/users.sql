CREATE TABLE users (
    id bigserial PRIMARY KEY,
    first_name varchar(50) NOT NULL CHECK (first_name <> ''),
    last_name varchar(50) NOT NULL CHECK (last_name <> ''),
    email varchar(254) NOT NULL
);
CREATE UNIQUE INDEX on users (lower(email));
