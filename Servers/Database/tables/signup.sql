CREATE TABLE signup (
    first_name varchar(50) NOT NULL CHECK (first_name <> ''),
    last_name varchar(50) NOT NULL CHECK (last_name <> ''),
    email varchar(254) NOT NULL,
    code smallint NOT NULL DEFAULT trunc(random()*9999), -- 0...9999
    created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE UNIQUE INDEX on signup (lower(email));
