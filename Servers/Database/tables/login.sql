CREATE TABLE login (
    email varchar(254) NOT NULL,
    code smallint NOT NULL DEFAULT trunc(random()*9999), -- 0...9999
    created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE UNIQUE INDEX on login (lower(email));
